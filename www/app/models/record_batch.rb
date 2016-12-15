class RecordBatch < ActiveRecord::Base
	has_many :records
	belongs_to :email_template
	belongs_to :sms_template
	belongs_to :join_form
	belongs_to :sender, class_name: 'Person'
	validate :one_template_provided

	scope :with_recipient_counts, -> { select(<<~SQL) }
		record_batches.*
		, (
				select 
					count(distinct recipient_id) 
				from 
					records 
				where 
					records.record_batch_id = record_batches.id
			) as recipient_count
			, (
				select 
					count(*) 
				from 
					subscriptions 
				where 
					not completed_at is null
					and person_id in (select recipient_id from records where record_batch_id = record_batches.id)
			) as completed_count
		SQL

	scope :desc, -> { order("record_batches.created_at desc")}

	def one_template_provided
		if sms_template.blank? && email_template.blank?
			errors.add(:base, "You must specify at least one sms or email template")
		end
	end

end
