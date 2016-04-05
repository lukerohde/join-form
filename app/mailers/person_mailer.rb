class PersonMailer < ApplicationMailer
	add_template_helper(ApplicationHelper)
	add_template_helper(SubscriptionsHelper)
	include SubscriptionsHelper

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

	def verify_email(subscription, subscription_params, request)
		@subscription = subscription
		@request = request
		uri = Addressable::URI.parse("#{request.protocol}#{request.host}:#{request.port}#{subscription_form_path(@subscription)}")
		
		params = subscription_callback_params(subscription_params)
		params = params.merge(person_params(subscription_params[:person_attributes]))
		uri.query_values = (uri.query_values || {}).merge(params)
		@url = uri.to_s

		mail(from: from(request), to: subscription.person.email, subject: "Please verify your email to continue joining")
	end

	def duplicate_notice(subscription, params, request)
		@subscription = subscription
		@request = request
		@params = params
		mail(from: from(request), to: subscription.join_form.person.email, subject: "We may be duplicating a member")
	end

private
	def from(request)
		"noreply@#{request.host}".gsub("www.", "")
	end
end
