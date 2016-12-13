class Record < ActiveRecord::Base
	belongs_to :sender, class_name: "Person"
	belongs_to :recipient, class_name: "Person"
	belongs_to :join_form
	belongs_to :record_batch

	def self.new_from_params(params)
 		result = Email.new if params['type'] && params['type'].downcase == 'email'
 		result ||= SMS.new

    result.template_id = params['template_id']
    result.join_form_id = params['join_form_id']
    result
  end
end
