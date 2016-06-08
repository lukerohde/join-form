# Preview all emails at http://localhost:3000/rails/mailers/email_template_mailer
class EmailTemplateMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/email_template_mailer/merge
  def merge
    EmailTemplateMailer.merge
  end

end
