class SendRecordBatchesJob < ActiveJob::Base
  include RecordsHelper
	include Rails.application.routes.url_helpers
  
  queue_as :default

  def perform(record_batch_id)
    ActiveRecord::Base.connection_pool.with_connection do
	  	#ActionMailer::Base.default_url_options => {:host=>ENV["APPLICATION_ROOT"]}

	  	@sms_messages = Record.where(type: 'SMS', record_batch_id: record_batch_id) || []
	  	@email_messages = Record.where(type: 'Email', record_batch_id: record_batch_id) || []

	  	@sms_messages.each do |r|
	  		send_sms(r)
	  	end

	  	@email_messages.each do |r|
	  		send_email(r)
	  	end
	  end
  end
end
