class EmailTemplates::PreviewController < ApplicationController
  include SubscriptionsHelper
	
	before_action :set_email_template
  before_action :set_subscription, only: [:new]
  before_action :authenticate_person!, except: [:pdf]
  layout 'pdf', only: [:pdf]



	def new
		@subject = Liquid::Template.parse(@email_template.subject).render(@data)
		
		if @email_template.body_html.present?
			@body_html = Liquid::Template.parse(@email_template.body_html).render(@data)
			@body_html_css = Roadie::Document.new(@body_html)
	    @body_html_css.add_css(@email_template.css)
	    @body_html_css.url_options = {host: ENV['mailgun_host'], protocol: "https"}
	    @body_html_css = @body_html_css.transform
		end
		
  	@pdf_html_css = get_pdf_html_css

		@body_plain = Liquid::Template.parse(@email_template.body_plain).render(@data).split('\r\n').join('<br/>')
	end

	def pdf
		@subscription = Subscription.find_by_token(params[:subscription_id])
		return render not_found unless @subscription.present? && @email_template.present?

		@data = merge_data(@subscription)
		@pdf_html_css = get_pdf_html_css # I don't really need inlined styles here, but (am lazy) and think it might be a good idea to keep html body styling and pdf styling as consistent as possible
	end

	def create
		EmailTemplateMailer.merge(@email_template.id, @subscription.id, params[:preview_email]).deliver_now
		redirect_to new_email_template_preview_path(@email_template, subscription_id: @subscription.id), notice: "Preview Email Sent"
	end

private

	def set_subscription
		@subscription = Subscription.find_by_id(params[:subscription_id])
		@subscription ||= Subscription.last
	  nuw_end_point_reload(@subscription)
	  @data = merge_data(@subscription)
		@prev = Subscription.where(['id < ?', @subscription.id]).last
		@next = Subscription.where(['id > ?', @subscription.id]).first
	end 

	def set_email_template
		@email_template = EmailTemplate.find(params[:email_template_id])
	end

	def get_pdf_html_css
		if @email_template.pdf_html.present?
			@pdf_html = Liquid::Template.parse(@email_template.pdf_html).render(@data)
			@pdf_html_css = Roadie::Document.new(@pdf_html)
	    @pdf_html_css.add_css(@email_template.css)
	    @pdf_html_css.url_options = {host: ENV['mailgun_host'], protocol: "https"}
	    @pdf_html_css = @pdf_html_css.transform
	    @pdf_html_css
		end
	end
end