module SubscriptionsHelper
  require 'addressable/uri'
  require 'rest-client'

	def pay_method_options(subscription)
    options_for_select(
      [
        'Credit Card',
        'Australian Bank Account',
      ], 
      subscription.pay_method
    )
  end

  def frequency_options(subscription)
    result = []
    f = subscription.join_form

    result << "Weekly - #{f.base_rate_weekly}" if f.base_rate_weekly
    result << "Fortnightly - #{f.base_rate_fortnightly}" if f.base_rate_fortnightly
    result << "Monthly - #{f.base_rate_monthly}" if f.base_rate_monthly
    result << "Quarterly - #{f.base_rate_quarterly}" if f.base_rate_quarterly
    result << "Half Yearly - #{f.base_rate_half_yearly}" if f.base_rate_half_yearly
    result << "Yearly - #{f.base_rate_yearly}" if f.base_rate_yearly
    
    current_selection = subscription.frequency || "Fortnightly"
    current_selection = result.find { |i| i.downcase.starts_with?(current_selection.downcase) }

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

  ##############################################
  ## membership api stuff 
  ## TODO refactor into end point, and workout 
  ## better data transformation scheme & cleaner 
  ## internal interface

  def end_point_uri
    Addressable::URI.parse("#{ENV['NUW_END_POINT']}/people")
  end

  def end_point_transform_subscription_to_person(subscription)
    result = person_params(subscription.person)
    result.merge!(subscription: end_point_transform_subscription_to_person_subscription(subscription.attributes))
  end

  def end_point_transform_subscription_to_person_subscription(subscription)
    # This is used in both directions!
    subscription = (subscription||{}).to_hash.symbolize_keys
    result = subscription.slice(:frequency, :plan, :pay_method)
    
    pm = 
      case result[:pay_method]
        when "Credit Card"
          subscription.slice(:card_number, :expiry_month, :expiry_year, :csv)
        when "Australian Bank Account"
          subscription.slice(:bsb, :account_number)
        end
    
    result.merge!(pm) if pm
    result
  end

  def end_point_person_put(subscription)
    payload = end_point_transform_subscription_to_person(subscription)

    #response = RestClient.put end_point_uri.to_s, payload.to_json, content_type: :json
    response = RestClient::Request.execute url: end_point_uri.to_s, method: :put, payload: payload.to_json, content_type: :json, verify_ssl: false
    
    JSON.parse(response.body)
  end

  def end_point_person_get(subscription_params)
    # TODO Timeout quickly and quietly
    payload = person_params(subscription_params[:person_attributes])
    #response = RestClient.get end_point_uri.to_s, :params => payload.to_hash
    # TODO verify cert
    response = RestClient::Request.execute url: end_point_uri.to_s, method: :get, payload: payload.to_hash, verify_ssl: false
    JSON.parse(response).symbolize_keys
  end

  def end_point_transform_person_to_subscription(person)
    subscription = end_point_transform_subscription_to_person_subscription(person[:subscription]).merge(join_form_id: @join_form.id)
    person = person_params(person) # membership's first_name and email should take precedence
    person.merge!(authorizer_id: @join_form.person.id, union_id: @join_form.union.id)
    subscription.merge!(person_attributes: person)
    subscription
  end

  def end_point_subscription_get(subscription_params)
    # Load a subscription out of membership, into this system
    result = nil
      
    person_data = end_point_person_get(subscription_params)
      
    unless person_data.blank?
      subscription_data = end_point_transform_person_to_subscription(person_data)
      result = Subscription.new(subscription_data)
      if person_data[:email] && (person = Person.find_by_email(person_data[:email]))
        if person.subscriptions.last
          # person already in system, with subscription
          result = person.subscriptions.last 
        else
          # person already in system, without subscription
          result.person = person
        end
        # update existing subscription and person with end point data
        patch_subscription(result, subscription_data)
      end
    end

    result
  end

  def fix_phone(number)
    (number||"").gsub(/[^0-9]/, '') # remove non-numeric characters
  end
end
