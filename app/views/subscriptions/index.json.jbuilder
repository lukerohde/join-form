json.record_batch_url new_record_batch_url
json.subscriptions do |subscriptions_element|
	subscriptions_element.array!(@subscriptions) do |subscription|
	  json.extract! subscription, :id, :token, :created_at, :updated_at
	  json.record_url new_subscription_record_url(subscription)
	end
end