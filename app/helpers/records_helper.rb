module RecordsHelper

  def format_mobile(mobile)
  	result = mobile
  	unless result.nil? 
  		result = result.gsub(/[^0-9+]/, '') # keep only numbers or the plus
  		result = result.gsub(/^(04)([0-9]{8})$/, '+614\2') # replace leading zero with +61
  	end
  	result
  end


  def send_sms(sms)
  	result = true
  	
    begin
      @client = Twilio::REST::Client.new ENV["twilio_sid"], ENV["twilio_token"]
    
      cb = records_update_sms_url(id: @record.id)
        
      sms = @client.messages.create(
	      from: sms.sender_address,
	      to: sms.recipient_address,
	      body: sms.body_plain,
	      statusCallback: cb =~ /localhost/ ? nil : cb
      )
    rescue StandardError => exception
    	result = false
      ExceptionNotifier.notify_exception(exception,
          :env => request.env, :data => {:message => "failed to send sms"})
      
    end
    
    result
  end
end


