class PersonMailer < ApplicationMailer
	add_template_helper(ApplicationHelper)

	def join_form_notice(person, join_form, request)
		@person = person
		@join_form = join_form
		@request = request
		mail(from: from(request), to: person.email, subject: "#{join_form.person.display_name} has created a join_form.")
	end

	def private_email(to, from, subject, body, request)
		@body = body
		mail(from: from.email, to: to.email, bcc: from.email, subject: subject)
	end

private
	def from(request)
		"noreply@#{request.host}".gsub("www.", "")
	end
end
