json.array!(@subscriptions) do |subscription|
  json.extract! subscription, :id, :person_id, :join_form_id, :frequency, :pay_method, :account_name, :account_number, :expiry, :ccv, :bsb
  json.url subscription_url(subscription, format: :json)
end
