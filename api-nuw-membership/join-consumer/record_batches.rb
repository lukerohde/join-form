require_relative "./api.rb"

module JOIN
	module RecordBatches
		extend JOIN::API

		# http://localhost:3000/locale/unions/nuw/join_forms/join_form_id/record_batches

		def self.post(locale:, name:, join_form_id:, sms_template_id:, email_template_id:, subscription_ids:)
			e = end_point_url(:record_batches)
			e = e.gsub('locale', locale)
			e = e.gsub('join_form_id', join_form_id)
		
			payload = {
			subscription_ids: subscription_ids, 
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