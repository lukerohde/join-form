class EmailTemplateMailer < ApplicationMailer
  include SubscriptionsHelper
  
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.email_template_mailer.merge.subject
  #
  def merge(email_template_id, subscription_id, to, cc = "", pdf_url = "")
    
    @subscription = Subscription.find(subscription_id)
    data = merge_data(@subscription)
    
    @email_template = EmailTemplate.find(email_template_id)
    @subject = Liquid::Template.parse(@email_template.subject).render(data)
    
    if @email_template.body_plain.present?
      @body_plain = Liquid::Template.parse(@email_template.body_plain).render(data)
    end

    if @email_template.body_html.present?
      @body_html = Liquid::Template.parse(@email_template.body_html).render(data)
      @body_html_css = Roadie::Document.new(@body_html)
      @body_html_css.add_css(@email_template.css)
      @body_html_css.url_options = {host: ENV['mailgun_host'], protocol: "https"}
      @body_html_css = @body_html_css.transform
    end

    # Attach pdf from URL passed in as param (probably the subscription join form)
    if pdf_url.present?
      file_name = "join_form_#{@subscription.external_id || @subscription.token}.pdf"
      begin
        attachments[file_name] = WickedPdf.new.pdf_from_url(pdf_url)
      rescue
        subject += " - #{file_name} failed to attach"
      end
    end

    # Attach PDF from email template designer
    if @email_template.pdf_html.present?
      @pdf_url = pdf_email_template_preview_url(@email_template, subscription_id: @subscription.token, locale: locale) 
      file_name = "#{@subscription.external_id || @subscription.token}.pdf"
      begin
        # TODO make this filename configurable
        attachments[file_name] = WickedPdf.new.pdf_from_url(@pdf_url)
      rescue
        @subject += " - #{file_name} failed to attach"
      end
    end


    mail to: to, cc: cc, from: "noreply@#{ENV['mailgun_host']}", subject: @subject 
  end
end