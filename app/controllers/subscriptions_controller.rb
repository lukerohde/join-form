class SubscriptionsController < ApplicationController
  before_action :authenticate_person!, except: [:show, :new, :create, :edit, :update]
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]
  before_action :set_join_form, except: [:index]
  before_action :resubscribe?, only: [:create]

  layout 'subscription', except: [:index]

  include SubscriptionsHelper

  # GET /subscriptions
  # GET /subscriptions.json
  def index
    @subscriptions = Subscription.eager_load([:person, :join_form]).order(:created_at).where('not subscriptions.person_id is null')
    @subscriptions = @subscriptions.where(['people.union_id = ?', current_person.union_id])
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
    if @subscription.new_record?
      result = @subscription.save
    else 
      if subscription_params['pay_method'] == "CC"
        result = @subscription.update_with_payment(subscription_params, @union)
      else
        result = @subscription.update(subscription_params)
      end 
    end

    if result
      notify 
      # TODO Guarentee delivery
      nuw_end_point_person_put(@subscription)
    end 

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
    return t('subscriptions.steps.done') if @subscription.pay_method_saved?
    return t('subscriptions.steps.payment') if @subscription.subscription_saved?
    return t('subscriptions.steps.plan') if @subscription.address_saved?
    return t('subscriptions.steps.address') if @subscription.contact_details_saved?  
    return t('subscriptions.steps.welcome')
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
      if @subscription.nil?
        forbidden
      else
        
        if @subscription.external_id && @subscription.updated_at < (Time.now - 1.hour)
          # If the subscription is linked (has external_id) 
          # Use when person is returning to their subscription, after more than 1 hour.

          @subscription = nuw_end_point_reload(@subscription) 
        end

        # blank these so they cannot be returned
        @subscription.card_number = ""
        @subscription.ccv = ""
        @subscription.account_number = ""
        @subscription.bsb = ""
        @subscription.stripe_token = ""
        if @subscription.person
          @subscription.person.email = "" if temporary_email?(@subscription.person.email)
          @subscription.person.first_name = "" if temporary_first_name?(@subscription.person.first_name)
          @subscription.person.last_name = "" if temporary_last_name?(@subscription.person.last_name)
        end 
      end
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

        # Hack date back to a regular format (for my API) TODO something better
        if params.dig(:subscription, :person_attributes, 'dob(1i)')
          #params[:subscription][:person_attributes][:dob] = "#{params['subscription']['person_attributes']['dob(1i)']}-#{params['subscription']['person_attributes']['dob(2i)']}-#{params['subscription']['person_attributes']['dob(3i)']}"
          dob_array = params[:subscription][:person_attributes].slice('dob(1i)', 'dob(2i)', 'dob(3i)').values.map(&:to_i)
          params[:subscription][:person_attributes][:dob] = Date.new(*dob_array).iso8601
          params[:subscription][:person_attributes].except!('dob(1i)', 'dob(2i)', 'dob(3i)')
        end
        
      end
      
      result = params.require(:subscription).permit(permitted_params << [data: (@join_form.schema[:columns]||[])])
    end

    def set_join_form
      id = params[:join_form_id] || params.dig(:subscription, :join_form_id) || @subscription.join_form.id
      
      if (Integer(id) rescue nil)
        @join_form = @union.join_forms.find(id)
      else
        # TODO Remove this hack when globalize works with rails 5
        zh_id = id + '-zh-tw' if locale.to_s.downcase == "zh-tw" && !id.include?("-zh-tw") 
        @join_form = @union.join_forms.where("short_name ilike ?",zh_id).first
        # END OF HACK
        @join_form = @union.join_forms.where("short_name ilike ?",id).first if @join_form.nil?
      end
    end

    def resubscribe?

      # setup some shortcuts
      params = subscription_params
      pparams = params[:person_attributes]

      # don't check resubscribe if the person is invalid, but do allow duplicate email. TODO dry up valiation logic - Subscription.new(params).valid? has a problem with duplicate email 
      return if pparams[:first_name].blank? || !Person.email_valid?(pparams[:email]) 
      
      # Check membership via API and create a subscription #TODO update this systems subscription with membership info 
      @subscription = nuw_end_point_load(params, @join_form)
      if @subscription
        # If an existing subcription exists, determine secure and appropriate action
        if current_person && current_person.union.id == @join_form.union.id
          # This is really nasty - TODO I want the logged in user to be able to avoid the verification steps, but have to review the original record first.
          patch_and_persist_subscription(params)
          redirect_to subscription_form_path(@subscription), notice: "We've matched a person already in our database!  Because you're logged in, redirected you to review and update this subscription instead."
        elsif nothing_to_expose(params, @subscription)
          # if the subscription from the database exposes no additional information
          # TODO fix bug where existing member with no address requires address validation
          patch_and_persist_subscription(params)
          redirect_to subscription_form_path(@subscription), notice: next_step_notice
        elsif params_match(params, @subscription)
          # if the user has provided enough contact detail to verify their identity, then they can update their subscription
          patch_and_persist_subscription(params)
          redirect_to subscription_form_path(@subscription), notice: t('subscriptions.steps.renewal')
        elsif ( @subscription.person.email.present? && !temporary_email?(@subscription.person.email) )
          # send email verfication message
          PersonMailer.verify_email(@subscription, params, request.host).deliver_later
          render :verify_email
        else
          # Can't verify identify so potentially create a duplicate
          PersonMailer.duplicate_notice(@subscription, params, request.host).deliver_later
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
      result = @subscription.save_without_validation!
      # TODO Guarantee delivery

      if result
        nuw_end_point_person_put(@subscription)
        notify
      end 

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
      sensitive.blank? # TODO make sure pay methods don't creep in
    end

    def notify
      #PersonMailer.temp_alert(@subscription, ENV['mailgun_host']).deliver_later 
      if @subscription.step == :thanks
        JoinNoticeJob.perform_later(@subscription)
      else
        IncompleteJoinNoticeJob.perform_in(30 * 60, @subscription, @subscription.updated_at.to_i)
      end
    end
end