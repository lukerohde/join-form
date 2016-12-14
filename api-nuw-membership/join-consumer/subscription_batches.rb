require_relative "./api.rb"

module JOIN
	module SubscriptionBatches
		extend JOIN::API

		# http://localhost:3000/locale/unions/nuw/join_forms/join_form_id/subscription_batches
		
		def self.post(locale:, join_form_id:, subscribers:)
			e = end_point_url(:subscription_batches)
			e = e.gsub('locale', locale)
			e = e.gsub('join_form_id', join_form_id)
		
			signed_post(e, subscribers)
		end
	end
end

