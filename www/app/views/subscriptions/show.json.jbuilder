json.extract! @subscription, :token, :created_at, :updated_at
json.url new_subscription_record_url(@subscription)