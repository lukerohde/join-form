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

  def subscription_api_params(subscription)
    subscription = (subscription||{}).to_hash.symbolize_keys
    result = subscription.slice(:frequency, :plan, :pay_method)
    
    pm = 
      case result[:pay_method]
        when "Credit Card"
          subscription.slice(:card_number, :expiry_month, :expiry_year, :csv)
        when "Australian Bank Account"
          subscription.slice(:bsb, :account_number)
        end
    
    result.merge!(subscription: pm) if pm
    result
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

  def callback_params(subscription)
    result = person_params(subscription.person)
    result.merge(subscription_callback_params(subscription))
  end

  def prefill_form(subscription, params)
    result = subscription_callback_params(params)
    result[:callback_url] = callback_url(result[:callback_url]) if result[:callback_url]
    
    result.each do |k,v|
      @subscription.write_attribute(k,v)
    end

    person_params(params).each do |k,v|
      @subscription.person.write_attribute(k,v)
    end
  end


  def call_people_end_point(params, method=:get)
    # TODO Timeout quickly and quietly
    uri = Addressable::URI.parse("http://localhost:4567/people")
    payload = person_params(params[:person_attributes])
    
    if method==:get
      uri.query_values = (uri.query_values || {}).merge(payload)
      response = Net::HTTP::get(uri)
      data = JSON.parse(response).symbolize_keys
    else
      payload.merge!({subscription: subscription_api_params(params)})
      #response = Net::HTTP.post_form(uri, payload)
      #data = JSON.parse(response.body).symbolize_keys
      response = response = RestClient.put uri.to_s, payload.to_json, content_type: :json
      data = JSON.parse(response.body)
    end

    data  
  end

  def get_membership_subscription(search_params)
    # Load a subscription out of membership, into this system
    subscription = nil
    membership_data = call_people_end_point(search_params)
    unless membership_data.blank?
      params = subscription_api_params(membership_data[:subscription]).merge(join_form_id: @join_form.id)
      
      if membership_data[:email] && (person = Person.find_by_email(membership_data[:email]))
        # This is an edge case, where a user of the system, is already a member, but doesn't have a subscription in this system
        person.update_attributes(person_params(membership_data).merge(authorizer_id: @join_form.person.id))
        if person.subscriptions.last
          subscription = person.subscriptions.last
        else
          subscription = Subscription.new(params)
          subscription.person = person
        end
      else
        person = person_params(membership_data) # membership's first_name and email should take precedence
        person.merge!(authorizer_id: @join_form.person.id, union_id: @join_form.union.id)
        params.merge!(person_attributes: person)
        subscription = Subscription.new(params)
      end
    end

    subscription
  end

  def fix_phone(number)
    (number||"").gsub(/[^0-9]/, '') # remove non-numeric characters
  end
end
