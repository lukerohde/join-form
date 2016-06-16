class EmailTemplates::PreviewController < ApplicationController
  include SubscriptionsHelper
	
	before_action :set_email_template
  before_action :set_subscription, only: [:new]
  
	def new
		@subject = Liquid::Template.parse(@email_template.subject).render(@data)
		
		@body_html = Liquid::Template.parse(@email_template.body_html).render(@data)
		@body_html_css = Roadie::Document.new(@body_html)
    @body_html_css.add_css(@email_template.css)
    @body_html_css.url_options = {host: ENV['mailgun_host'], protocol: "https"}
    @body_html_css = @body_html_css.transform
		
		@body_plain = Liquid::Template.parse(@email_template.body_plain).render(@data).split('\r\n').join('<br/>')
	end

	def create
		EmailTemplateMailer.merge(@email_template.id, @data, params[:preview_email]).deliver_now
		redirect_to new_email_template_preview_path(@email_template, subscription_id: @subscription.id), notice: "Preview Email Sent"
	end

private

	def set_subscription
		@subscription = Subscription.find_by_id(params[:subscription_id])
		@subscription ||= Subscription.last
	  nuw_end_point_reload(@subscription)
	  @data = flatten_subscription(@subscription)
		@prev = Subscription.where(['id < ?', @subscription.id]).last
		@next = Subscription.where(['id > ?', @subscription.id]).first
	end 

	def set_email_template
		@email_template = EmailTemplate.find(params[:email_template_id])
	end
end