
class MailLoggerObserver
  def self.delivered_email(mail)
		if mail.header['filing_subject'].present?
			
			mail.to = [ENV['filing_email']]
			mail.subject = mail.header['filing_subject']
			mail.header['filing_subject'] = nil # prevent infinite loop ;)
			
			mail.deliver
		end
  end
end

class MailDevelopmentInterceptor
  def self.delivering_email(mail)
    if Rails.env.development?
      mail.subject = "#{mail.subject} [#{(mail.to||[]).join(',')} #{(mail.cc||[]).join(',')}] "
			mail.to = ENV['developer_email']
      mail.cc = nil
      mail.bcc = nil
    end
  end
end

ActionMailer::Base.register_observer(MailLoggerObserver)
ActionMailer::Base.register_interceptor(MailDevelopmentInterceptor)


