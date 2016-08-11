json.extract! @subscription, :token, :created_at, :updated_at
json.url renew_join_url(@subscription.join_form.union.short_name, @subscription.join_form.short_name, @subscription.token, locale: 'en')