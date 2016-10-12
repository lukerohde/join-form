class SubscriptionsController < ApplicationController
  before_action :allow_iframe
  before_action :authenticate_person!, except: [:show, :new, :create, :edit, :update, :renew]
  before_action :set_subscription, only: [:show, :edit, :update, :destroy, :end_point_put]
  before_action :set_join_form, except: [:index, :temp_report]
  before_action :facebook_new, only: [:create]
  skip_before_action :verify_authenticity_token, if: :api_request?, only: [:create, :renew]
  before_filter :verify_hmac, if: :api_request?, only: [:create, :renew]
  before_action :set_authorizer, only: [:new]
  before_action :resubscribe?, only: [:create]
  #layout 'subscription', except: [:index]
  
  include SubscriptionsHelper

  # GET /subscriptions
  # GET /subscriptions.json
  def index
    @subscriptions = Subscription.eager_load([:person, :join_form]).order('subscriptions.created_at desc').where('not subscriptions.person_id is null')
    @subscriptions = @subscriptions.where(['people.union_id = ?', current_person.union_id])
  end

  # GET /subscriptions/1
  # GET /subscriptions/1.json
  def show

  end

  def setup_new
    @subscription = Subscription.new
    @subscription.person = Person.new
    @subscription.join_form = @join_form
    @subscription.source = params[:source] || request.referer
  end

  # GET /subscriptions/new
  def new
    setup_new
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
    @subscription.renewal = false
    
     # this is a crude hack to hide address, and probably should be a part of the address model on person
    #   - country_code can be provided by the underpayment calculator as a query param for prefilling
    #   - alternatively the system will geolocate the IP address
    @subscription.set_country_code(params["country_code"] || request.location)
    
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

  def renew
    request.body.rewind # needed for integration test
    
    data = check_signature(JSON.parse(request.body.read)) # check it again only to remove the hmac
    @subscriptions = nuw_end_point_receive(data, @join_form)
    
    # save an array of subscriptions
    success = [false]
    begin
      Subscription.transaction do 
        success = @subscriptions.map(&:save_without_validation!)
        raise ActiveRecord::Rollback unless success.all?
      end 
    rescue
    end
    
    respond_to do |format|
      if success.all?
        format.json { render :index }
      else
        format.json { render json: @subscriptions.select {|s| !s.errors.blank?}, status: :unprocessable_entity }
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

  def end_point_put
    # If saving to the API failed, provide a way for the user to retry
    nuw_end_point_person_put(@subscription)
    notify(true) # send notices, even though its admin logged in
    notice = @subscription.end_point_put_required ? "Subscription failed to save" :  "Subscription saved and message(s) sent" 
    redirect_to request.referer, notice: notice
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
      result = @subscription.save if result && @subscription.signature_vector.present?  # workaround possible bug with carrierwave not saving the name of the image uploaded until second save
    end

    if result
      # TODO Guarentee delivery
      nuw_end_point_person_put(@subscription)
      notify # I imagine notify can update the time stamp and prevent the delayed message from sending.
    end 
    result
  end

  def temp_report
    report = ""
    ctot = 0
    ftot = 0 

    JoinForm.all.each do |j|
      subscriptions = j.subscriptions.where(['created_at > ? and not person_id is null', Time.parse(params[:since]||'1900-01-01')])
      subscriptions.each do |s|
        if (s.updated_at < (Time.now - 1.hour) && !s.end_point_put_required) 
          nuw_end_point_reload(s) rescue nil
        end
      end  
      
      complete = subscriptions.select{|s| ['Paying', 'Awaiting 1st payment'].include?(s.status) }
      followup = subscriptions.select{|s| !['Paying', 'Awaiting 1st payment'].include?(s.status) }
      
      ctot += complete.count
      ftot += followup.count

      if complete.count > 0
        report += "\r\n\r\n-- #{j.short_name.upcase} completes --\r\n"
        report += complete.collect {|s| "#{s.external_id} #{s.person.display_name}, #{s.step} (#{s.status||"Pending"}), #{edit_join_url(s.join_form.union.short_name, s.join_form.short_name, s.token)}"}.join("\r\n")
        report += "\r\nTOTAL: #{complete.count}\r\n"
      end
      if followup.count > 0
        report += "\r\n\r\n-- #{j.short_name.upcase} for follow up --\r\n"
        report += followup.collect {|s| "#{s.external_id} #{s.person.display_name}, #{s.step} (#{s.status||"Pending"}), #{edit_join_url(s.join_form.union.short_name, s.join_form.short_name, s.token)}"}.join("\r\n")
        report += "\r\nTOTAL: #{followup.count}\r\n"
      end
    end

    report += "\r\nCOMPLETE TOTAL: #{ctot}   FOLLOWUP TOTAL: #{ftot}\r\n"
    render text: report, layout: false, content_type: 'text/plain'
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
    return t('subscriptions.steps.plan') if @subscription.address_saved? || !@subscription.address_required?
    return t('subscriptions.steps.address') if @subscription.contact_details_saved?  
    return t('subscriptions.steps.welcome')
  end

  # DELETE /subscriptions/1
  # DELETE /subscriptions/1.json
  def destroy
    @subscription.destroy rescue nil
    respond_to do |format|
      if @subscription.destroyed?
        format.html { redirect_to request.referer || subscriptions_url, notice: 'Subscription was successfully destroyed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to request.referer || subscriptions_url, notice: "Could not delete subscription"
        }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
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
        if @subscription.external_id && @subscription.updated_at < (Time.now - 1.hour) && !@subscription.end_point_put_required
          # If the subscription is linked (has external_id) 
          # Use when person is returning to their subscription, after more than 1 hour.
          @subscription = nuw_end_point_reload(@subscription) 
        end

        # blank these so they cannot be returned
        @subscription.card_number = ""
        @subscription.ccv = ""
        @subscription.account_number = ""
        @subscription.bsb = ""
        if @subscription.person
          @subscription.person.email = "" if temporary_email?(@subscription.person.email)
          @subscription.person.first_name = "" if temporary_first_name?(@subscription.person.first_name)
          @subscription.person.last_name = "" if temporary_last_name?(@subscription.person.last_name)
        end 
        @subscription.signature_vector = "" unless current_person.present? || params[:pdf] == 'true' # users can't sign, but do see the signature; non-users always have to sign and don't see the sig
      end
    end

    def set_join_form
      id = params[:join_form_id] || params.dig(:subscription, :join_form_id) || @subscription.join_form.id
      
      if (Integer(id) rescue nil)
        @join_form = @union.join_forms.find(id)
      else
        @join_form = @union.join_forms.where("short_name ilike ?",id).first if @join_form.nil?
      end
      @subscription.join_form = @join_form if @subscription
    end

    def resubscribe?

      # setup some shortcuts
      params = subscription_params
      pparams = params[:person_attributes]

      # don't check resubscribe if the person is invalid, but do allow duplicate email. TODO dry up valiation logic - Subscription.new(params).valid? has a problem with duplicate email unfortunately so I can't use that.
      return if pparams[:first_name].blank? || !Person.email_valid?(pparams[:email]) 
      # Check membership via API and create a subscription #TODO update this systems subscription with membership info 
      @subscription = nuw_end_point_load(params, @join_form)
      if @subscription
        @subscription.renewal = true
        
        # If an existing subcription exists, determine secure and appropriate action
        if current_person && current_person.union.id == @join_form.union.id
          # This is really nasty - TODO I want the logged in user to be able to avoid the verification steps, but have to review the original record first.
          #patch_and_persist_subscription(params)
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

    def patch_and_persist_subscription(subscription_params)
      # ActiveRecords update and assign_attributes
      # can't handle overwriting an existing record
      # with a new record. IDs and other data gets 
      # blanked.  This is designed to overwrite
      # attributes with only those params that are 
      # present
      patch_subscription(@subscription, subscription_params)
      result = @subscription.save_without_validation!
      # TODO Guarantee delivery

      if result
        nuw_end_point_person_put(@subscription)
        #binding.pry if @subscription.step == 'thanks' && params[:action] == 'create'
        notify unless params[:action] == 'create' # prevent resubscribers with bank details getting a welcome on the first step
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

    def set_authorizer
      # This is a crude way of one system letting this system know if the user is acting on another's behalf
      session[:authorizer_id] = params[:authorizer_id] if params[:authorizer_id]
    end

    def notify(resend = false)
      #PersonMailer.temp_alert(@subscription, ENV['mailgun_host']).deliver_later 
      if @subscription.step == :thanks
        #JoinNoticeJob.perform_later(@subscription.id)
        admin_notice if send_admin_notice?(resend)
        welcome if send_welcome?(resend)
      else
        IncompleteJoinNoticeJob.perform_in(30 * 60, @subscription.id, @subscription.updated_at.to_i)
      end
    end

    def admin_notice
      begin
        template_id = @subscription.join_form.admin_email_template_id
        if template_id.present?
          to = @subscription.join_form.person.email
          cc = @subscription.join_form.followers(Person).collect(&:email).join(',')
          pdf_url = "#{edit_join_url(@subscription.join_form.union.short_name, @subscription.join_form.short_name, @subscription.token, locale: 'en', pdf: true)}"
          EmailTemplateMailer.merge(template_id, @subscription.id, to, cc, pdf_url).deliver_later
        else
          JoinNoticeJob.perform_later(@subscription.id)
        end
      rescue Exception => exception
        ExceptionNotifier.notify_exception(exception,
          :env => request.env, :data => {:message => "failed to send welcome email"})
      end
    end

    def welcome
      # I'm being cautious here due to the complexity, but should not be required with 'deliver_later' which would ordinarily crash in the background and send an exception
    
      begin
        if template_id = @subscription.join_form.welcome_email_template_id
          EmailTemplateMailer.merge(template_id, @subscription.id, @subscription.person.email, "", "", "welcome_email").deliver_later
        end
      rescue Exception => exception
        ExceptionNotifier.notify_exception(exception,
          :env => request.env, :data => {:message => "failed to send welcome email"})
      end
    end

    def user_other_than_subscriber? 
      (current_person.present? && current_person.email != @subscription.person.email) || 
        (session[:authorizer_id].present? && session[:authorizer_id] != @subscription.person.email)
    end

    def send_admin_notice?(resend = false)
      result = true
      # don't send welcome if someone is logged in, or the authorizer's email != the subcribers email
      result = false if user_other_than_subscriber? && !resend
      result
    end

    def send_welcome?(resend = false)
      result = true
      # end point mocked in testing, don't want welcome done until membership can calculate what it has to calculate
      result = false if @subscription.end_point_put_required && !Rails.env.test? 
      # don't send welcome if someone is logged in, or the authorizer's email != the subcribers email
      result = false if user_other_than_subscriber? && !resend
      result
    end


    def api_request?
      request.format.json? || request.format.xml?
    end 

    def verify_hmac
      #puts 'checking hmac'
      check_signature(JSON.parse(request.body.read))
    end

    def allow_iframe
      #response.headers.except! 'X-Frame-Options'
      #response.headers['X-Frame-Options'] = 'ALLOW-FROM https://apps.facebook.com'  
      response.headers.delete('X-Frame-Options')
    end

    def facebook_new
      # Facebook page tab sends a post request to your url
      # I'm attempting a redirect to get to make it work
      if 
        (request.referer =~ /facebook/ && params['signed_request'].present?) ||
        (request.headers['origin'] =~ /thunderpenny/ && params['proxy'].present?)
        setup_new
        #redirect_to request.path
        render :new
      end
    end


    # Never trust parameters from the scary internet, only allow the white list through.
    def subscription_params
      return {} unless params[:subscription].present? # needed for api testing

      if params[:subscription][:person_attributes].present?
        params[:subscription][:person_attributes][:union_id] = @join_form.union.id
        if current_person
          params[:subscription][:person_attributes][:authorizer_id] = current_person.id
        else
          params[:subscription][:person_attributes][:authorizer_id] = @join_form.person.id
        end

        # Hack date back to a regular format (for my API) TODO something better
        dob_array = params[:subscription][:person_attributes].slice('dob(1i)', 'dob(2i)', 'dob(3i)').values.map(&:to_i) - [0]
        if (dob_array.length == 3 && dob = Date.new(*dob_array).iso8601 rescue nil)
          params[:subscription][:person_attributes][:dob] = dob
        end 
        params[:subscription][:person_attributes].except!('dob(1i)', 'dob(2i)', 'dob(3i)')
      end
      
      # Reject keys from pay methods that are not being submitted
      params[:subscription].except!(:stripe_token, :expiry_month, :expiry_year, :card_number, :ccv) unless params[:subscription][:pay_method] == "CC"
      params[:subscription].except!(:bsb, :account_number) unless params[:subscription][:pay_method] == "AB"

      # intercept and save partial card details before encryption
      params[:subscription][:partial_card_number] = params[:subscription][:card_number].gsub(/\d(?=.{3})/,'X') if params[:subscription][:card_number].present?
      params[:subscription][:partial_account_number] = params[:subscription][:account_number].gsub(/\d(?=.{3})/,'X') if params[:subscription][:account_number].present?
      params[:subscription][:partial_bsb] = params[:subscription][:bsb].gsub(/\d(?=.{3})/,'X') if params[:subscription][:bsb].present?
      
      params[:subscription][:end_point_put_required] = true
      result = params.require(:subscription).permit(permitted_params << [data: (@join_form.schema_data[:columns]||[])])
    end
end