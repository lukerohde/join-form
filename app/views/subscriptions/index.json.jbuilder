json.array!(@subscriptions) do |subscription|
  json.extract! subscription, :id, :person_id, :join_form_id, :frequency, :pay_method
  json.url subscription_url(subscription, format: :json)
end
