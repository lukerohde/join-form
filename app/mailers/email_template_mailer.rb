class EmailTemplateMailer < ApplicationMailer
  include SubscriptionsHelper
  
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.email_template_mailer.merge.subject
  #
  def merge(email_template_id, subscription_id, email)
    @subscription = Subscription.find(subscription_id)
    data = merge_data(@subscription)
    
    @email_template = EmailTemplate.find(email_template_id)
    @subject = Liquid::Template.parse(@email_template.subject).render(data)
    @body_html = Liquid::Template.parse(@email_template.body_html).render(data)
    @body_plain = Liquid::Template.parse(@email_template.body_plain).render(data)
    @body_html_css = Roadie::Document.new(@body_html)
    @body_html_css.add_css(@email_template.css)
    @body_html_css.url_options = {host: ENV['mailgun_host'], protocol: "https"}
    @body_html_css = @body_html_css.transform

    if @email_template.pdf_html.present?
      @pdf_url = pdf_email_template_preview_url(@email_template, subscription_id: @subscription.token, locale: locale) 
      begin
        attachments["#{@subscription.external_id || @subscription.token}.pdf"] = WickedPdf.new.pdf_from_url(@pdf_url)
      rescue
        @subject += " - PDF FAILED TO ATTACH"
      end
      
    end

    mail to: email, from: "noreply@#{ENV['mailgun_host']}", subject: @subject 
  end
end