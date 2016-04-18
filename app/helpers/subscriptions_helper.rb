module SubscriptionsHelper
  require 'addressable/uri'
  require 'rest-client'
  require 'openssl'

	def pay_method_options(subscription)
    options_for_select(
      [
        [t('subscriptions.pay_method.edit.credit_card'), 'CC'],
        [t('subscriptions.pay_method.edit.au_bank_account'), 'AB']
      ], 
      subscription.pay_method
    )
  end

  def frequency_options(subscription)
    result = []
    f = subscription.join_form

    result << ["#{t('subscriptions.subscription.edit.weekly')} - #{number_to_currency(f.base_rate_weekly, locale: @locale)}", "W"] if f.base_rate_weekly
    result << ["#{t('subscriptions.subscription.edit.fortnightly')} - #{number_to_currency(f.base_rate_fortnightly, locale: @locale)}", "F"] if f.base_rate_fortnightly
    result << ["#{t('subscriptions.subscription.edit.monthly')} - #{number_to_currency(f.base_rate_monthly, locale: @locale)}", "M"] if f.base_rate_monthly
    result << ["#{t('subscriptions.subscription.edit.quarterly')} - #{number_to_currency(f.base_rate_quarterly, locale: @locale)}", "Q"] if f.base_rate_quarterly
    result << ["#{t('subscriptions.subscription.edit.half_yearly')} - #{number_to_currency(f.base_rate_half_yearly, locale: @locale)}", "H"] if f.base_rate_half_yearly
    result << ["#{t('subscriptions.subscription.edit.yearly')} - #{number_to_currency(f.base_rate_yearly, locale: @locale)}", "Y"] if f.base_rate_yearly
    
    current_selection = subscription.frequency || "F"
    current_selection = result.find { |i| i[1] == current_selection.upcase }

    options_for_select(
      result, 
      current_selection
    )

  end

  def subscription_form_path(subscription)
    join_form = subscription.join_form
    union = join_form.union

    if subscription.id
      #union_join_form_subscription_path(union.short_name, join_form.short_name, subscription.token)
      "/#{union.short_name.downcase}/#{join_form.short_name.downcase}/join/#{subscription.token}"
    else
      "/#{union.short_name.downcase}/#{join_form.short_name.downcase}/join"
    end
  end

  def subscription_short_path
    "/#{@union.short_name.downcase}/#{@join_form.short_name.downcase}/#{@subscription.token}"
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
    result = result.reject {|k,v| v.blank? }
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
      :frequency,
      :plan,
      :pay_method,
      :callback_url
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
      subscription.write_attribute(k,v) unless v.blank?
    end

    params[:person_attributes].each do |k,v|
      if k.to_sym == :authorizer_id
        subscription.person.authorizer_id = v unless v.blank?
      else
        subscription.person.write_attribute(k,v) unless v.blank?
      end
    end
  end


  ###############################################
  # TODO Refactor API Stuff

  def nuw_end_point_uri
    Addressable::URI.parse("#{ENV['NUW_END_POINT']}/people")
  end

  def nuw_end_point_reload(subscription)
    if subscription.person.present? && subscription.person.external_id.present?
      payload = nuw_end_point_person_get(person_attributes: {external_id: subscription.person.external_id})
      subscription.person.authorizer_id = subscription.join_form.person.id
      subscription.update_from_end_point(payload)
    end
    subscription
  end

  def nuw_end_point_load(subscription_params, join_form)
    subscription = nil
    
    payload = nuw_end_point_person_get(subscription_params)
    unless payload.blank? 
      person = Person.find_by_external_id(payload.dig(:person_parameters, :external_id)) if payload.dig(:person_parameters, :external_id)
      person ||= Person.find_by_email(subscription_params.dig(:person_attributes, :email)) if subscription_params.dig(:person_attributes, :email)
      person ||= Person.find_by_email(payload[:email]) if payload[:email]
      person ||= Person.new()

      subscription = person.subscriptions.last unless person.new_record?
      subscription ||= Subscription.new(person: person)

      subscription.join_form_id = join_form.id
      person.authorizer_id = join_form.person.id
      person.union_id = join_form.union.id
    
      subscription.update_from_end_point(payload)
    else
      person = Person.find_by_email(subscription_params.dig(:person_attributes, :email))
      if person
        subscription = person.subscriptions.last
        subscription ||= Subscription.new(person: person)
      end
    end

    subscription
  end


  def nuw_end_point_person_get(subscription_params)
    # TODO Timeout quickly and quietly
    url = nuw_end_point_uri
    
    payload = person_params(subscription_params[:person_attributes])
    payload = nuw_end_point_sign(url.to_s, payload)
    
    url.query_values = (url.query_values || {}).merge(payload)
    
    response = RestClient::Request.execute url: url.to_s, method: :get, verify_ssl: false
    nuw_end_point_transform_from(JSON.parse(response).deep_symbolize_keys)
  end
  
  def nuw_end_point_person_put(subscription)
    url = nuw_end_point_uri
    
    payload = nuw_end_point_transform_to(subscription)
    payload = nuw_end_point_sign(url.to_s, payload)
    response = RestClient::Request.execute url: url.to_s, method: :put, payload: payload.to_json, content_type: :json, verify_ssl: false
    
    result = JSON.parse(response.body).deep_symbolize_keys
    nuw_api_process_put_response(subscription, result)
    result
  end

  def nuw_api_process_put_response(subscription, payload)
    subscription.person.external_id = payload[:external_id]
    subscription.person.authorizer_id = @join_form.person.id

    payments = payload.dig(:subscription, :payments)

    subscription.payments.each do |p1|
      if p1.external_id.nil?
        p2 = payments.find {|p3| p3[:id] == "nuw_api_#{p1.id}"} # this feels horrible, maybe I should do this on natural key like timestamp and amount
        p1.external_id = p2[:external_id] if p2.present? # if it can't id a payment, then it'll keep posting it
      end
    end
    
    # TODO after card details have been posted, they are no longer required
    #subscription.card_number = nil
    #subscription.ccv = nil
    #subscription.bsb = nil
    #subscription.account_number = nil

    subscription.save_without_validation!
  end

  def nuw_end_point_sign(url, payload)
    # convert to json and back to fix date formats
    # sort to make sure param order is consistent (only json payloads have nested params and these dont need to be sorted)
    data = url + JSON.parse(payload.sort.to_json).to_s
    hmac = Base64.encode64("#{OpenSSL::HMAC.digest('sha1',ENV['NUW_END_POINT_SECRET'], data)}")
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
    # This is used in both directions!
    result = subscription_hash.slice(:frequency, :plan, :pay_method)

    pm = 
      case result[:pay_method]
        when "CC"
          subscription_hash.slice(:card_number, :expiry_month, :expiry_year, :ccv)
        when "AB"
          subscription_hash.slice(:bsb, :account_number)
        end
    
    result.merge!(pm) if pm
    result
  end

  def nuw_end_point_transform_from_person(person_hash)
    result = person_params(person_hash)
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
    result = hash.slice(:frequency, :plan)
    result[:establishment_fee] = subscription.total

    if subscription.pay_method_saved?
      pm = 
        case subscription.pay_method
          when "CC"
            hash.slice(:pay_method, :card_number, :expiry_month, :expiry_year, :ccv)
          when "AB"
            hash.slice(:pay_method, :bsb, :account_number)
          end
    
      result.merge!(pm) if pm
    end

    result
  end

  def temporary_email
    '#{SecureRandom.hex(8)}@unknown.com' # TODO pray for no clashes
  end

  def temporary_email?(email)
    (email =~ /.{16}@unknown.com/) == 0
  end

  def temporary_first_name
    'unknown'
  end

  def temporary_last_name?(last_name)
    last_name.downcase == 'unknown'
  end

  def temporary_first_name?(first_name)
    first_name.downcase == 'unknown'
  end  

  def fix_phone(number)
    (number||"").gsub(/[^0-9]/, '') # remove non-numeric characters
  end

end
