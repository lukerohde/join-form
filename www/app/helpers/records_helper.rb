module RecordsHelper

  def format_mobile(mobile)
  	result = mobile
  	unless result.nil? 
  		result = result.gsub(/[^0-9+]/, '') # keep only numbers or the plus
  		result = result.gsub(/^(04)([0-9]{8})$/, '+614\2') # replace leading zero with +61
  	end
  	result
  end

  def reply_to(email)
    email.gsub(/@.*/, "@#{ENV['mailgun_domain']}")
  end

  def send_message(record)
    if record.type == 'SMS'
      send_sms(record)
    else
      send_email(record)
    end
  end

  def send_email(email)
    if email.body_html.present?
      PersonMailer.follow_up_email_html(email.recipient, email.sender, email.sender_address, email.subject, email.body_plain, email.body_html, email.message_id, "join_email").deliver_later
    else
      PersonMailer.follow_up_email_plain(email.recipient, email.sender, email.sender_address, email.subject, email.body_plain, email.message_id, "join_email").deliver_later
    end
  end

  def send_sms(sms)
    result = true
  	
    begin
      @client = Twilio::REST::Client.new ENV["twilio_sid"], ENV["twilio_token"]
    
      cb = records_update_sms_url(id: sms.id, host: ENV['APPLICATION_ROOT']) 
      msg = @client.messages.create(
	      from: sms.sender_address,
	      to:  Rails.env.development? ? ENV['developer_mobile'] : sms.recipient_address,
	      body: sms.body_plain,
	      statusCallback: cb =~ /localhost/ ? nil : cb
      )
      FilingMailer::file_sms(sms.body_plain, sms.recipient.try(:id), "join_sms").deliver_later
    rescue StandardError => exception
    	result = false
      if defined?(request)
        ExceptionNotifier.notify_exception(exception,
          :env => request.env, :data => {:message => "failed to send sms"})
      end
    end
    
    result
  end
end

