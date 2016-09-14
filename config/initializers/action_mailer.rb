
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

ActionMailer::Base.register_observer(MailLoggerObserver)

