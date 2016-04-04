class PersonMailer < ApplicationMailer
	add_template_helper(ApplicationHelper)
	add_template_helper(SubscriptionsHelper)

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

	def resubscribe_notice(subscription, request)
		@subscription = subscription
		@request = request
		mail(from: from(request), to: subscription.person.email, subject: "Please verify your email to continue joining")
	end

private
	def from(request)
		"noreply@#{request.host}".gsub("www.", "")
	end
end
