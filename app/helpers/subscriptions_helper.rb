module SubscriptionsHelper
  require 'addressable/uri'
  require 'rest-client'
  require 'openssl'
  include ActionView::Helpers::NumberHelper

  def start_hidden(step)
    @subscription.step == step ? "start_hidden" : ""
  end

	def pay_method_options(subscription)
    result = []
    result << [t('subscriptions.pay_method.edit.use_existing'), "-"] if subscription.has_existing_pay_method?
    result << [t('subscriptions.pay_method.edit.credit_card'), 'CC']
    result << [t('subscriptions.pay_method.edit.au_bank_account'), 'AB']
    
    options_for_select(
      result, 
      subscription.has_existing_pay_method? ? "-" : (subscription.pay_method || "CC")
    )
  end

  def frequency_options(subscription)
    result = []
    form = subscription.join_form

    %w(W F M Q H Y).each do |freq|
      result << ["#{friendly_frequency(freq)} - #{friendly_fee(form, freq)}", freq] if form.fee(freq) > 0
    end

    current_selection = subscription.frequency || "F"
    current_selection = result.find { |i| i[1] == current_selection.upcase }
    current_selection = result[0] unless current_selection
    
    options_for_select(
      result, 
      current_selection
    )

  end
  
  def friendly_frequency(freq)
    case freq
      when "W"
        t('subscriptions.subscription.edit.weekly')
      when "F" 
        t('subscriptions.subscription.edit.fortnightly')
      when "M" 
        t('subscriptions.subscription.edit.monthly')
      when "Q" 
        t('subscriptions.subscription.edit.quarterly')
      when "H" 
        t('subscriptions.subscription.edit.half_yearly')
      when "Y" 
        t('subscriptions.subscription.edit.yearly')
      else
        #raise "Unknown frequency '#{freq}'"
      end
  end

  def friendly_fee(join_form, freq)
    fee = join_form.fee(freq)
    if fee.present? && fee > 0
      number_to_currency(fee, locale: locale)
    else
      ""
    end
  end

  def callback_url(url, extra_params = {})
    u = Addressable::URI.parse(url)
    bad_request unless u.scheme

    q = u.query_values || {}    
    q.merge!(extra_params)
    u.query_values = JSON.parse(q.to_json) # convert all values to string e.g. dob

    u.to_s
  rescue
    bad_request
  end

  def person_params(person)
    # this is used for both calling system call back
    # and membership API
    result = person.slice(:external_id,*sensitive_person_params)
    result = result.reject do |k,v| 
      if [:address1, :address2, :suburb, :state, :postcode].include?(k.to_sym)
        person[:address1].blank?
      else
        v.blank?
      end
    end
    result
  end

  def sensitive_person_params
    [
      :first_name, 
      :last_name, 
      :dob,
      :email,
      :mobile,
      :gender,
      :address1,
      :address2,
      :suburb,
      :state,
      :postcode
    ]
  end

  def subscription_callback_params(subscription)
    result = subscription.slice(
      :plan,
      :pay_method,
      :callback_url,
      :status, 
      :next_payment_date,
      :financial_date
      )
    result = result.reject {|k,v| v.blank? }
  end


  def permitted_params
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
          :signature_vector,
          :partial_bsb, 
          :partial_account_number,
          :partial_card_number,
          :end_point_put_required, 
          person_attributes: [
              :external_id,
              :first_name,
              :last_name,
              :gender,
              :dob, 
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
        ]
  end

  def flatten_subscription(subscription)
    result = person_params(subscription.person)
    result.merge(subscription_callback_params(subscription))
  end

  def flatten_subscription_params(params)
    result = person_params(params[:person_attributes])
    result.merge(subscription_callback_params(params))
  end

  def unflatten_subscription_params(params)
    result = subscription_callback_params(params)
    result[:callback_url] = callback_url(result[:callback_url]) if result[:callback_url]
    result[:person_attributes] = person_params(params)
    result
  end

  def prefill_form(subscription, params)
    params = unflatten_subscription_params(params)
    patch_subscription(subscription, params)
  end

  def patch_subscription(subscription, params)
    params.except(:person_attributes).each do |k,v|
      subscription.send("#{k}=", v) unless v.blank?
    end

    params[:person_attributes].each do |k,v|
      subscription.person.send("#{k}=", v) unless v.blank?
    end
  end


  def merge_data(subscription)
    # For Email Merge
    result = subscription.attributes
    result.merge!(subscription.person.attributes)
    result.merge!({
        'frequency' => (friendly_frequency(subscription[:frequency])||"").downcase,
        'fee' => friendly_fee(subscription.join_form, subscription[:frequency]),
        'formatted_up_front_payment' => number_to_currency(subscription[:up_front_payment], locale: locale)
      })
    result.reject!{|k,v| v.nil? }
    result["url"] = @subscription_url = "#{join_url(subscription.join_form.union.short_name, subscription.join_form.short_name, subscription.token, locale: 'en')}"
    
    result
  end


  ###############################################
  # TODO Refactor API Stuff

  def nuw_end_point_uri
    Addressable::URI.parse("#{ENV['NUW_END_POINT']}/people")
  end

  def nuw_end_point_reload(subscription)
    if subscription.person.present? && subscription.person.external_id.present?
      if payload = nuw_end_point_person_get(person_attributes: {external_id: subscription.person.external_id})
        subscription.person.authorizer_id = subscription.join_form.person.id
        
        # My API adds mock values so the subscription can be saved. 
        # Remove them here, because we don't them wanting to be overridden
        # TODO figure out why this feels so wrong - It shouldn't be the APIs responsbility nor can it be the models, maybe these values should be added not in person get, but in NUW endpoint load
        payload[:person_attributes] = payload[:person_attributes].except(:email) if temporary_email?(payload[:person_attributes][:email])
        payload[:person_attributes] = payload[:person_attributes].except(:first_name) if temporary_first_name?(payload[:person_attributes][:first_name])
        payload[:person_attributes] = payload[:person_attributes].except(:last_name) if temporary_last_name?(payload[:person_attributes][:last_name])

        subscription.update_from_end_point(payload)
      end
    end
    subscription
  end

  def nuw_end_point_load(subscription_params, join_form)
    subscription = nil
    payload = nuw_end_point_person_get(subscription_params)
    unless payload.blank? 
      # something found via the api, update existing record
      person = Person.find_by_external_id(payload.dig(:person_parameters, :external_id)) if payload.dig(:person_parameters, :external_id)
      person ||= Person.find_by_email(subscription_params.dig(:person_attributes, :email)) if subscription_params.dig(:person_attributes, :email)
      person ||= Person.find_by_email(payload[:email]) if payload[:email]
      person ||= Person.new()

      subscription = person.subscriptions.last unless person.new_record?
      subscription ||= Subscription.new(person: person) # person exists without a subscription (user)

      subscription.join_form_id = join_form.id
      person.authorizer_id = join_form.person.id
      person.union_id = join_form.union.id
    
      subscription.update_from_end_point(payload) # this will save
    else
      # nothing found in api, may still be someone already in this database
      person = Person.find_by_email(subscription_params.dig(:person_attributes, :email))
      if person
        subscription = person.subscriptions.last
        subscription ||= Subscription.new(person: person)
        # TODO I don't like that subscription might be unsaved, but should only affect admins
      end
    end

    subscription  # might be nil if nothing found in this system or api
  end


  def nuw_end_point_person_get(subscription_params)
    # TODO Timeout quickly and quietly
    url = nuw_end_point_uri
    
    payload = person_params(subscription_params[:person_attributes])
    payload = nuw_end_point_sign(url.to_s, payload)
    
    url.query_values = (url.query_values || {}).merge(payload)
    
    begin
      response = RestClient::Request.execute url: url.to_s, method: :get, verify_ssl: false
      nuw_end_point_transform_from(JSON.parse(response).deep_symbolize_keys)
    rescue Exception => exception
      # TODO A catch all like this is pretty nasty.
      ExceptionNotifier.notify_exception(exception,
        :env => request.env, :data => {:message => "nuw_end_point_person_get failed but was caught"})
      
      nil 
    end
  end
  
  def nuw_end_point_person_put(subscription)
    url = nuw_end_point_uri
    payload = nuw_end_point_transform_to(subscription)
    payload = nuw_end_point_sign(url.to_s, payload)
    begin
      response = RestClient::Request.execute url: url.to_s, method: :put, payload: payload.to_json, content_type: :json, verify_ssl: false
      result = JSON.parse(response.body).deep_symbolize_keys
      nuw_api_process_put_response(subscription, result)
      result
    rescue Exception => exception
      # TODO A catch all like this is pretty nasty.
      ExceptionNotifier.notify_exception(exception,
        :env => request.env, :data => {:message => "nuw_end_point_person_put failed but was caught"})
      
      nil 
    end
  end

  def nuw_api_process_put_response(subscription, payload)
    subscription.person.external_id = payload[:external_id]
    subscription.person.authorizer_id = @join_form.person.id
    subscription.status = payload.dig(:subscription, :status)
    subscription.next_payment_date = payload.dig(:subscription, :next_payment_date)
    subscription.financial_date = payload.dig(:subscription, :financial_date)
    
    payments = payload.dig(:subscription, :payments)

    # receipt payments
    if payments.present?
      subscription.payments.each do |p1|
        if p1.external_id.nil?
          p2 = payments.find {|p3| p3[:id] == "nuw_api_#{p1.id}"} # this feels horrible, maybe I should do this on natural key like timestamp and amount
          p1.external_id = p2[:external_id] if p2.present? # if it can't id a payment, then it'll keep posting it
        end
      end
    end
    
    # TODO after card details have been posted, they are no longer required (even encrypted)
    if subscription.pay_method_saved?
      subscription[:card_number] = nil
      subscription[:ccv] = nil
      subscription[:account_number]= nil
      subscription[:bsb] = nil 

      # keep partial details so we know how a member pay, for welcome
      subscription[:pay_method] = payload.dig(:subscription, :pay_method)
      subscription[:partial_bsb] = payload.dig(:subscription, :partial_bsb)
      subscription[:partial_account_number] = payload.dig(:subscription, :partial_account_number)
      # TODO Test stripe token invalidation, remarked until then 
      #subscription[:stripe_token] = nil if subscription[:partial_card_number] != payload.dig(:subscription, :partial_card_number) # if the card number changes, then our stripe token is probably invalid
      subscription[:partial_card_number] = payload.dig(:subscription, :partial_card_number)
      subscription[:expiry_month] = payload.dig(:subscription, :expiry_month)
      subscription[:expiry_year] = payload.dig(:subscription, :expiry_year)
      
      subscription[:first_recurrent_payment_date] = payload.dig(:subscription, :first_recurrent_payment_date)
      subscription[:up_front_payment] = payload.dig(:subscription, :up_front_payment)
      
      #subscription[:expiry] = nil
      #subscription.pay_method = "-" # dash indicates that the details are already on the system
    end 
    
    subscription[:end_point_put_required] = false
    subscription.save_without_validation!
  end

  def nuw_end_point_sign(url, payload)
    # convert to json and back to fix date formats
    # sort to make sure param order is consistent (only json payloads have nested params and these dont need to be sorted)
    secret = ENV['NUW_END_POINT_SECRET']
    raise "NUW_END_POINT_SECRET not configured" unless secret
    data = url + JSON.parse(payload.sort.to_json).to_s
    hmac = Base64.encode64("#{OpenSSL::HMAC.digest('sha1',secret, data)}")
    payload.merge!(hmac: hmac)
    payload
  end

  ## Transform from NUW end point format
 
  def nuw_end_point_transform_from(payload)
    result = nil
    unless payload.blank? 
      result = nuw_end_point_transform_from_subscription(payload[:subscription])
      result[:person_attributes] = nuw_end_point_transform_from_person(payload)
      result[:payments_attributes] = nuw_end_point_transform_from_payments(payload.dig(:subscription, :payments))
    end
    result
  end

  def nuw_end_point_transform_from_subscription(subscription_hash)
    return {} if subscription_hash.nil?
    result = subscription_hash.slice(:frequency, :plan, :pay_method, :status, :next_payment_date, :financial_date)
    pm = 
      case result[:pay_method]
        when "CC"
          subscription_hash.slice(:card_number, :partial_card_number, :expiry_month, :expiry_year, :ccv)
        when "AB"
          subscription_hash.slice(:bsb, :partial_bsb, :account_number, :partial_account_number, :up_front_payment, :first_recurrent_payment_date)
        end
    
    result.merge!(pm) if pm
    result
  end

  def nuw_end_point_transform_from_person(person_hash)
    result = person_params(person_hash)
    # TODO Is it appropriate to fake here - I would have thought that'd be a concern of something higher up.
    result[:email] = temporary_email if result[:email].blank?
    result[:first_name] = temporary_first_name if result[:first_name].blank?
    result 
  end


  def nuw_end_point_transform_from_payments(payments_hash)
    payments_hash || []
  end

  ## Tranform to end point format ##
  def nuw_end_point_transform_to(subscription)
    result = nuw_end_point_transform_to_person(subscription.person)
    payments = nuw_end_point_transform_to_payments(subscription.payments.where("external_id is null"))
    subscription = nuw_end_point_transform_to_subscription(subscription)
    subscription[:payments] = payments
    result[:subscription] = subscription
    result
  end

  def nuw_end_point_transform_to_person(person)
    person_params(person)
  end

  def nuw_end_point_transform_to_payments(payments)
    payments
      .select{|p| p.amount > 0 && p.external_id.nil?}
      .collect { |p| p.attributes.to_hash }
  end

  def nuw_end_point_transform_to_subscription(subscription)
    hash = subscription.attributes.symbolize_keys
    result = hash.slice(:frequency, :plan, :data)
    result[:url] = ENV['APPLICATION_ROOT'] + subscription_form_path(subscription)

    if subscription.pay_method_saved?
      result[:establishment_fee] = subscription.total
      pm = 
        case subscription.pay_method
          when "CC"
            hash.slice(:pay_method, :card_number, :expiry_month, :expiry_year, :ccv)
          when "AB"
            hash.slice(:pay_method, :bsb, :account_number)
          else 
            { pay_method: "-" } if result[:establishment_fee] >= 0.01 # is including a symbol to indicate existing pm a bad idea? A shared literal seems so.
          end
    
      result.merge!(pm) if pm
    end

    result
  end

  def temporary_email
    "#{SecureRandom.hex(8)}@unknown.com" # TODO pray for no clashes
  end

  def temporary_email?(email)
    (email =~ /.{16}@unknown.com/) == 0
  end

  def temporary_first_name
    'unknown'
  end

  def temporary_last_name?(last_name)
    (last_name||"").downcase == 'unknown'
  end

  def temporary_first_name?(first_name)
    (first_name||"").downcase == 'unknown'
  end  

  def fix_phone(number)
    (number||"").gsub(/[^0-9]/, '') # remove non-numeric characters
  end

end
