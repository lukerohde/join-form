class EmailTemplates::PreviewController < ApplicationController
  before_action :set_email_template

	def new
		@subject = Liquid::Template.parse(@email_template.subject).render(sample_data)
		
		@body_html = Liquid::Template.parse(@email_template.body_html).render(sample_data)
		@body_html_css = Roadie::Document.new(@body_html)
    @body_html_css.add_css(@email_template.css)
    @body_html_css.url_options = {host: ENV['mailgun_host'], protocol: "https"}
    @body_html_css = @body_html_css.transform
		
		@body_plain = Liquid::Template.parse(@email_template.body_plain).render(sample_data).split('\r\n').join('<br/>')
		
	end

	def create
		EmailTemplateMailer.merge(@email_template.id, sample_data, params[:preview_email]).deliver_now
		redirect_to new_email_template_preview_path(@email_template), notice: "Preview Email Sent"
	end

private
	
	def sample_data
		{
			name: "Luke"
		}.with_indifferent_access
	end

	def set_email_template
		@email_template = EmailTemplate.find(params[:email_template_id])
	end
end