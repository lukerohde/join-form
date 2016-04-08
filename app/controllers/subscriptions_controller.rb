class SubscriptionsController < ApplicationController
  before_action :authenticate_person!, except: [:show, :new, :create, :edit, :update]
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]
  before_action :set_join_form
  before_action :resubscribe?, only: [:create]

  layout 'subscription'

  include SubscriptionsHelper

  # GET /subscriptions
  # GET /subscriptions.json
  def index
    @subscriptions = Subscription.all
  end

  # GET /subscriptions/1
  # GET /subscriptions/1.json
  def show
  end

  # GET /subscriptions/new
  def new
    @subscription = Subscription.new
    @subscription.person = Person.new
    @subscription.join_form = @join_form
    
    prefill_form(@subscription, params)
  end

  # GET /subscriptions/1/edit
  def edit
    prefill_form(@subscription, params)
  end

  # POST /subscriptions
  # POST /subscriptions.json
  def create
    @subscription = Subscription.new(subscription_params)
  
    respond_to do |format|
      if save_step
        format.html { redirect_to next_step, notice: next_step_notice }
        format.json { render :show, status: :created, location: @subscription }
      else
        format.html { render :new }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subscriptions/1
  # PATCH/PUT /subscriptions/1.json
  def update
    respond_to do |format|
      if save_step
        format.html { redirect_to next_step, notice: next_step_notice }
        format.json { render :show, status: :ok, location: @subscription }
      else
        format.html { render :edit }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  def save_step
    result = false
    if subscription_params['pay_method'] == "Credit Card"
      result = @subscription.update_with_payment(subscription_params, @union)
    else
      result = @subscription.update(subscription_params)
    end 

    # TODO Guarentee delivery
    end_point_person_put(@subscription) if result
      
    result
  end

  def next_step
    unless @subscription.pay_method_saved?
      #edit_subscription_path @subscription.token
      subscription_form_path(@subscription)
    else
      #subscription_path @subscription.token
      if @subscription.callback_url.present?
        callback_url(@subscription.callback_url, flatten_subscription(@subscription))
      else
        subscription_short_path # uses @subscription
      end
    end
  end

  def next_step_notice
    return 'Thank you for joining' if @subscription.pay_method_saved?
    return 'Please provide a payment method' if @subscription.subscription_saved?
    return 'Please choose your membership type' if @subscription.address_saved?
    return 'Please tell us your address' if @subscription.contact_details_saved?  
  end

  # DELETE /subscriptions/1
  # DELETE /subscriptions/1.json
  def destroy
    @subscription.destroy
    respond_to do |format|
      format.html { redirect_to subscriptions_url, notice: 'Subscription was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find_by_token(params[:id])    
      @subscription = Subscription.find(params[:id]) if @subscription.nil? and current_person # only allow if user logged in
      forbidden if @subscription.nil?
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def subscription_params
      
      if params[:subscription][:person_attributes].present?
        params[:subscription][:person_attributes][:union_id] = @join_form.union.id
        if current_person
          params[:subscription][:person_attributes][:authorizer_id] = current_person.id
        else
          params[:subscription][:person_attributes][:authorizer_id] = @join_form.person.id
        end
      end

      result = params.require(:subscription).permit(permitted_params)
    end

    def set_join_form
      id = params[:join_form_id] || params.dig(:subscription, :join_form_id) 
      
      if (Integer(id) rescue nil)
        @join_form = @union.join_forms.find(id)
      else
        @join_form = @union.join_forms.where("short_name ilike ?",id).first
      end
    end

    def resubscribe?
      # Check if renewing/resubscribing, and determine appropriate and secure next step
      person = Person.find_by_email(params.dig(:subscription,:person_attributes,:email))
      @subscription = person.subscriptions.last if person
      # TODO Fix bug where someone has an admin account, but no subscription yet (possibly by patching a blank subscription with a membership one)

      # Check membership via API and create a subscription #TODO update this systems subscription with membership info 
      @subscription = end_point_subscription_get(subscription_params) unless @subscription
      if @subscription
        # If an existing subcription exists, determine secure and appropriate action
        if current_person && current_person.union.id == @join_form.union.id
          # This is really nasty - I want the logged in user to be able to avoid the verification steps, but have to review the original record first.
          # if an admin is logged in they can view and update any matched subscriber
          @subscription.assign_attributes(subscription_params) if subscription_params[:person_attributes][:external_id] # We've already matched them
          
          if @subscription.new_record? && !@subscription.save
            flash[:notice] = "We've matched a person already in our database! Because you're logged in, we've discarded your input and loaded this subscription for you to review and update instead."
            render :new 
          else
            redirect_to subscription_form_path(@subscription), notice: "We've matched a person already in our database!  Because you're logged in, redirected you to review and update this subscription instead."
          end 
        elsif nothing_to_expose(subscription_params, @subscription)
          # if the subscription from the database exposes no additional information
          # TODO fix bug where existing member with no address requires address validation
          patch_and_persist_subscription(subscription_params)
          redirect_to subscription_form_path(@subscription), notice: next_step_notice
        elsif params_match(subscription_params, @subscription)
          # if the user has provided enough contact detail to verify their identity, then they can update their subscription
          patch_and_persist_subscription(subscription_params)
          redirect_to subscription_form_path(@subscription), notice: "We've found an existing subscription for you to update or renew."
        elsif @subscription.person.email.present?     
          if @subscription.new_record? 
            @subscription.person.first_name = "unknown" if @subscription.person.first_name.blank?
            @subscription.save # TODO How do I handle this failure
          end
          # send email verfication message
          PersonMailer.verify_email(@subscription, subscription_params, request).deliver_now
          render :verify_email
        else
          # Can't verify identify so potentially create a duplicate
          PersonMailer.duplicate_notice(@subscription, subscription_params, request).deliver_now
        end
      end
    end

    def patch_and_persist_subscription(params)
      # ActiveRecords update and assign_attributes
      # can't handle overwriting an existing record
      # with a new record. IDs and other data gets 
      # blanked.  This is designed to overwrite
      # attributes with only those params that are 
      # present
      patch_subscription(@subscription, params)
      result = @subscription.save
      # TODO Guarantee delivery
      end_point_person_put(@subscription) if result
      result
    end

    def params_match(params, subscription)
      # We want to avoid email verification if the user
      # has provided enough information to verify their 
      # identity
      p1 = params[:person_attributes]
      p2 = subscription.person.attributes.symbolize_keys

      score = 0
      score += 1 if (p1[:first_name].present? && p1[:first_name].downcase == (p2[:first_name]||"").downcase) || (p1[:last_name].present? && p1[:last_name].downcase == (p2[:last_name]||"").downcase )
      score += 1 if p1[:mobile].present? && fix_phone(p1[:mobile]) == fix_phone(p2[:mobile])
      score += 1 if p1[:email].present? && p1[:email] == p2[:email]
      #score += 1 if params[:external_id] == subscription[:external_id]
      score += 1 if p1[:dob].present? && Date.parse(p1[:dob]) == p2[:dob] rescue nil
       
      score >= 3 
    end

    def nothing_to_expose(params, subscription)
      p1 = params[:person_attributes]
      p2 = subscription.person.attributes.symbolize_keys
      
      # remove blank and identical keys
      p2.reject! do |k,v|
        v.blank? || p1[k].present?
      end

      # select sensitive keys
      sensitive = p2.slice(*sensitive_person_params)

      # if the hash has nothing
      sensitive.blank?
    end
end
