class FilingMailer < ApplicationMailer


	def file_email(msg, person_id = nil, tags = "")
		if to = ENV['filing_email']
			msg = Mail.new(msg)
			person = Person.find_by_id(person_id)
			attachments = msg.attachments
			@subject = "DONE: #{tags} #{msg.subject} #{'(' + person.external_id + ')' if person}"
			@body = (msg.text_part || msg).body.raw_source
			mail to: to, from: msg.from, body: @body, subject: @subject
		end 
	end

	def file_sms(msg, person_id = nil, tags = "")
		if to = ENV['filing_email']
			person = Person.find_by_id(person_id)
			@subject = "DONE: #{tags} SMS to #{person.try(:display_name)} #{'(' + person.external_id + ')' if person}"
			mail to: to, body: msg, subject: @subject
		end
	end
end