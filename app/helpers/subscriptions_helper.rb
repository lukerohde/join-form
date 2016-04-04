module SubscriptionsHelper
  require 'addressable/uri'

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

    query_values = u.query_values || {}
    u.query_values = query_values.merge(extra_params)

    u.to_s
  rescue
    bad_request
  end

  def person_params(person)
    person.slice(
      :first_name, 
      :last_name, 
      :date_of_birth,
      :email,
      :mobile,
      :gender,
      :address1,
      :address2,
      :suburb,
      :state,
      :postcode
    )
  end

  def subscription_callback_params(subscription)
    subscription.slice(
      :frequency,
      :plan,
      :pay_method
      )
  end

  def subscription_api_params(subscription)
    subscription = subscription.to_hash.symbolize_keys
    result = subscription.slice(:frequency, :plan, :pay_method)
    
    pm = 
      case result[:pay_method]
        when "Credit Card"
          subscription.slice(:card_number, :expiry_month, :expiry_year, :csv)
        when "Australian Bank Account"
          subscription.slice(:bsb, :account_number)
        end
    
    result.merge(subscription: pm) if pm
    result
  end

  def callback_params(subscription)
    result = person_params(subscription.person)
    result.merge(subscription_callback_params(subscription))
  end

  def call_people_end_point(params, method=:get)
    uri = Addressable::URI.parse("http://localhost:4567/people")
    
    payload = person_params(params[:person_attributes])
    payload.merge({subscription: subscription_api_params(params)})

    if method==:get
      uri.query_values = (uri.query_values || {}).merge(payload)
      response = Net::HTTP::get(uri)
      data = JSON.parse(response).symbolize_keys
    else
      response = Net::HTTP.post_form(uri, payload)
      data = JSON.parse(response.body).symbolize_keys
    end

    data  
  end

  def get_membership_subscription(params)
    # Load a subscription out of membership, into this system
    data = call_people_end_point(params)
    result = subscription_api_params(data[:subscription]).merge(join_form_id: @join_form.id)
    
    if data[:email] && (@person = Person.find_by_email(data[:email]))
      # This is an edge case, where a user of the system, is already a member, but doesn't have a subscription in this system
      @person.update_attributes(person_params(data).merge(authorizer_id: @join_form.person.id))
      subscription = Subscription.new(result)
      subscription.person = @person
    else
      result = result.merge(person_attributes: person_params(data).merge(authorizer_id: @join_form.person.id, union_id: @join_form.union.id))
      subscription = Subscription.new(result)
    end
    
    if subscription.save
      subscription
    else
      nil
    end
  end
end
