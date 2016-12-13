json.record_batch_url new_union_join_form_record_batch_url(@union, @join_form)
json.subscriptions do |subscriptions_element|
	subscriptions_element.array!(@subscriptions) do |subscription|
	  json.extract! subscription, :id, :token, :created_at, :updated_at
	  json.record_url new_subscription_record_url(subscription)
	end
end
