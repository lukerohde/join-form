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
    
      sms = @client.messages.create(
	      from: sms.sender_address,
	      to: sms.recipient_address,
	      body: sms.body_plain,
	      statusCallback: records_update_sms_url(id: @record.id)#http://7165b168.ngrok.io/records/update_sms?id=#{}"
	    )
	  rescue
    	result = false
    end
    
    result
  end
end


