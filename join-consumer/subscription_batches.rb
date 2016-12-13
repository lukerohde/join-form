module JOIN
	module SubscriptionBatches
		extend API

		def self.post(locale:, name:, join_for_id:, sms_template_id:, email_template_id:, subscriber_ids:)
			end_point = end_point_url(:subscription_batches)
			e = e.gsub('locale', locale)
			e = e.gsub('join_form_id', join_form_id)
		
			payload = {
			subscriber_ids: subscriber_ids, 
			record_batch: {
					name: name, 
					sms_template_id: sms_template_id, 
					email_template_id: email_template_id
				}
			}
			signed_post(e, payload)
		end
	end
end