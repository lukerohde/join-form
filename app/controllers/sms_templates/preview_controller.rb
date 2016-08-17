class SmsTemplates::PreviewController < ApplicationController
	include SubscriptionsHelper
		
	before_action :set_sms_template
  before_action :set_subscription, only: [:new, :create]

	def new
		@body = render_body
	end

	def create
		@client = Twilio::REST::Client.new ENV["twilio_sid"], ENV["twilio_token"]
    
    @client.messages.create(
      from: ENV["twilio_number"],
      to: params['preview_sms'],
      body: render_body,
    )
    
		redirect_to new_sms_template_preview_path(@sms_template, subscription_id: @subscription.id), notice: "Preview SMS Sent"
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

 	def render_body
 		Liquid::Template.parse(@sms_template.body).render(@data)
	end

	def set_sms_template
		@sms_template = SmsTemplate.find(params[:sms_template_id])
	end

end