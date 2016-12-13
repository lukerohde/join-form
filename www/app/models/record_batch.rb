class RecordBatch < ActiveRecord::Base
	has_many :records
	belongs_to :email_template
	belongs_to :sms_template
	belongs_to :join_form
	belongs_to :sender, class_name: 'Person'
	validate :one_template_provided

	def one_template_provided
		if sms_template.blank? && email_template.blank?
			errors.add(:base, "You must specify at least one sms or email template")
		end
	end

end
