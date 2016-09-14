class FilingMailer < ApplicationMailer


	def file_sms(msg, person_id = nil, tags = "")
		if to = ENV['filing_email']
			person = Person.find_by_id(person_id)
			@subject = "DONE: #{tags} SMS to #{person.try(:display_name)} #{'(' + person.external_id + ')' if person}"
			mail to: to, body: msg, subject: @subject
		end
	end
end