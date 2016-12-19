class PersonMailer < ApplicationMailer
	add_template_helper(ApplicationHelper)
	add_template_helper(SubscriptionsHelper)
	include SubscriptionsHelper
  include ApplicationHelper

	def join_form_notice(person, join_form, request, creator)
		@person = person
		@join_form = join_form
		@request = request
		@creator = creator
		mail(from: from(request), to: person.email, subject: "#{creator.display_name} has started designin a new join form.")
	end

	def private_email(to, from, subject, body, reply_url = nil)
		@reply_url = reply_url
		@body = body
		mail(from: from.email, bcc: from.email, to: to.email, subject: subject)
	end

	def reply_email(to, from, subject, body, reply_url = nil, tags = "")
		@reply_url = reply_url
		@body = body
		headers['filing_subject'] = "DONE: #{tags} #{subject} (#{from.external_id})"
		
		mail(from: from.email, to: to.email, subject: subject)
	end

	def follow_up_email_html(to, from, reply_to, subject, body_plain, body_html, message_id, tags = "")
		@body_plain = body_plain
		@body_html = body_html
		
		headers['filing_subject'] = "DONE: #{tags} #{subject} (#{to.external_id})"
		
		mail = mail(from: from.email, to: to.email, reply_to: reply_to, subject: subject)
		#headers['Message-Id'] = message_id # for reply tracking.
		mail.mailgun_headers = {'Message-Id' => message_id}
		mail
	end

	def follow_up_email_plain(to, from, reply_to, subject, body_plain, message_id, tags = "")
		@body_plain = body_plain
		
		headers['filing_subject'] = "DONE: #{tags} #{subject} (#{to.external_id})"
		
		mail = mail(from: from.email, to: to.email, reply_to: reply_to, subject: subject)
		#headers['Message-Id'] = message_id # for reply tracking.
		mail.mailgun_headers = {'Message-Id' => message_id}
		mail
	end

	def verify_email(subscription, subscription_params, host)
		@subscription = subscription
		uri = Addressable::URI.parse("https://#{host}#{subscription_form_path(@subscription)}")
		
		# TODO refactor to share helper flattening for callback
		params = flatten_subscription_params(subscription_params)
		uri.query_values = (uri.query_values || {}).merge(params)
		@url = uri.to_s

		headers[:bcc]= 'lrohde@nuw.org.au'

		mail(from: "noreply@#{host}", to: subscription.person.email, subject: t('subscriptions.verify_email.subject'))
	end

	def duplicate_notice(subscription, params, host)
		@subscription = subscription
		@params = params
		mail(from: "noreply@#{host}", to: 'lrohde@nuw.org.au', subject: "We may be duplicating a member")
	end

	def temp_alert(subscription, host)
		@subscription = subscription
		subject = "#{@subscription.person.present? ? @subscription.person.display_name : 'unknown' } - #{@subscription.step}"
		mail(from: "noreply@#{host}", to: 'lrohde@nuw.org.au', subject: subject)
	end

	def subscription_pdf(subscription, to, cc, subject)
		#PersonMailer.attach_pdf(Subscription.find_by_token('21TBslpIDBcDaO-C76GVBg'), 'lrohde@nuw.org.au').deliver_now
		@subscription = subscription
		@subscription_url = "#{edit_join_url(subscription.join_form.union.short_name, subscription.join_form.short_name, subscription.token, locale: 'en')}"
		@pdf_url = "#{edit_join_url(subscription.join_form.union.short_name, subscription.join_form.short_name, subscription.token, locale: 'en', pdf: true)}"
		@host = "www.#{host}"
		begin
			attachments["join_form_#{subscription.external_id || subscription.token}.pdf"] = WickedPdf.new.pdf_from_url(@pdf_url)
		rescue
			subject += " - PDF Error"
		end
		mail(from: "noreply@#{host}", to: to, cc: cc, subject: subject )
	end

private
	def from(request)
		"noreply@#{request.host}".gsub("www.", "")
	end

	def host
		ENV['mailgun_host']
	end

end
