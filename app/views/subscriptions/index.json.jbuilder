json.batch_message_url "/batch"
json.subscriptions do |subscriptions_element|
	subscriptions_element.array!(@subscriptions) do |subscription|
	  json.extract! subscription, :id, :token, :created_at, :updated_at
	  json.message_url new_subscription_record_url(subscription)
	end
end