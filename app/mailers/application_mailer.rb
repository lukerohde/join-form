class ApplicationMailer < ActionMailer::Base
  default from: "noreply@#{ENV['mailgun_host']}"
  layout 'mailer'
end
