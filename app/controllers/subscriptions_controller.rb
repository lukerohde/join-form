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
    
    # attempt to parse any callback_url, upfront, so developers can test it works
    @subscription.callback_url = callback_url(params[:callback_url]) if params[:callback_url]
  end

  # GET /subscriptions/1/edit
  def edit
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
    if subscription_params['pay_method'] == "Credit Card"
      @subscription.update_with_payment(subscription_params, @union)
    else
      @subscription.update(subscription_params)
    end 
  end

  def next_step
    unless @subscription.pay_method_saved?
      #edit_subscription_path @subscription.token
      subscription_form_path(@subscription)
    else
      #subscription_path @subscription.token
      if @subscription.callback_url.present?
        callback_url(@subscription.callback_url, callback_params(@subscription))
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

      result = params.require(:subscription).permit(
        [
          :join_form_id, 
          :frequency, 
          :pay_method, 
          :card_number, 
          :expiry_month,
          :expiry_year,
          :ccv, 
          :stripe_token, 
          :account_name, 
          :account_number, 
          :bsb, 
          :plan, 
          :callback_url,
          person_attributes: [
              :first_name,
              :last_name,
              :gender,
              :email,
              :mobile,
              :address1, 
              :address2,
              :suburb,
              :state,
              :postcode,
              :union_id,
              :authorizer_id,
              :id
            ]
        ])
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
      # Verify by email # TODO consider setting a password and requiring login, or backing up details, and overwriting them (without exposing any)
      # TODO Ideally I'd like to treat an application as a join form, not expose any details, backup old details, update with new details, rather than having this nasty email verification step
      # If we match people on more than email, this method becomes insecure when the person matched doesn't have an email (unless we sms verify)

      person = Person.find_by_email(params.dig(:subscription,:person_attributes,:email))
      subscription = @person.subscriptions.last if @person
      
      # Check membership via API and create a subscription
      subscription = get_membership_subscription(subscription_params) unless @subscription
      
      # If an existing subcription exists, determine secure and appropriate action
      if subscription && current_person && current_person.union.id == @join_form.union.id
        # if an admin is logged in they can view and update any matched subscriber
        redirect_to subscription_form_path(subscription), notice: "Person already in our database!  Because you're logged in, we've redirected you to update their existing subscription."
      elsif subscription && params_match(params, subscription)
        # if the user has provided enough contact detail to verify their identity, then they can update their subscription
        redirect_to subscription_form_path(subscription), notice: "We've found an existing subscription for you to renew."
      elsif subscription && subscription.email.present?     
        # send message
        PersonMailer.verify_email_notice(subscription, request).deliver_now
      
        # redirect
        render :verify_email
      else
        # Create a duplicate
        PersonMailer.duplicate_notice(subscription, subscription_params, request).deliver_now
      end
    end

    def params_match(params, subscription)
      # We want to avoid email verification if the user
      # has provided enough information to verify their 
      # identity

      score = 0
      score += 1 if params[:first_name] == subscription[:first_name] 
      score += 1 if params[:last_name] == subscription[:last_name]
      score += 1 if params[:mobile] == subscription[:mobile]
      score += 1 if params[:email] == subscription[:email]
      #score += 1 if params[:external_id] == subscription[:external_id]
      #score += 1 if params[:dob] == subscription[:dob]
      
      score >= 3 # first name and last name and one piece of contact detail may not be enough, alternatively they can have two pieces of contact detail and a typo in one name
    end
end
