class FilingMailer < ApplicationMailer


	def file(msg, person_id)
		binding.pry
		msg = Mail.new(msg)
		person = Person.find(person_id)
		attachments = msg.attachments
		@subject = "DONE: #{person.external_id if person} #{msg.subject}"
		mail to: ENV['filing_email'], from: person.email, body: msg.text_part.body.raw_source, subject: @subject
	end
end