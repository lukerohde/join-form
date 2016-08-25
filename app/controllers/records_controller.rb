class RecordsController < ApplicationController
  before_action :set_record, only: [:show, :edit, :update, :destroy]
  before_action :set_subscription, except: [:receive_sms, :update_sms]
  before_action :set_person, except: [:receive_sms, :update_sms]
  before_action :set_join_form, except: [:receive_sms, :update_sms]

  skip_before_filter :verify_authenticity_token, :only => [:receive_sms, :update_sms]
  skip_before_filter :authenticate_person!, :only => [:receive_sms, :update_sms]

  include RecordsHelper
  include SubscriptionsHelper

  # GET /records
  # GET /records.json
  def index
    @records = Record.all
  end

  # GET /records/1
  # GET /records/1.json
  def show
  end

  # GET /records/new
  def new
    body = ""
    if params['template_id'].present?
      template = SmsTemplate.find(params['template_id'])
      body = Liquid::Template.parse(template.body).render(merge_data(@subscription))
    end

    @sms = Record.new({
      type: "SMS",
      body_plain: body
    })

    @history = Record.where(["sender_id = ? or recipient_id = ?", @person.id, @person.id])
  end

  def receive_sms
    replying_to = Record.where(recipient_address: format_mobile(params['From'])).last
    from = replying_to.recipient
    to = replying_to.sender

    begin 
      PersonMailer.private_email(to, from, "SMS Reply from #{from.first_name} #{from.last_name}", params[:Body], request, new_subscription_record_url(from.subscriptions.last)).deliver_now     
  
      # This is crude - maybe I should record the private_email above, or send to NUW Assist and have an API call for all NUW Assist messages!
      @sms = Record.create({
        sender_address: format_mobile(params['From']), 
        recipient_address: ENV['twilio_number'], # should this be to.email
        sender: from,
        recipient: to, 
        type: "SMS",
        body_plain: params['Body'], 
        delivery_status: 'received'
      })

    rescue Exception => exception
      ExceptionNotifier.notify_exception(exception,
        :env => request.env, :data => {:message => "failed to relay or record incoming SMS"})
    end
    
    render xml: Twilio::TwiML::Response.new.to_xml
    
  end

  def update_sms
    @sms = Record.find(params[:id])
    @sms.update({delivery_status: params[:MessageStatus]})
    render xml: Twilio::TwiML::Response.new.to_xml
  end

  # POST /records
  # POST /records.json
  def create
    # parse message incase there is some liquid directive pasted in
    @record = Record.new(record_params)
    @record.body_plain = Liquid::Template.parse(@record.body_plain).render(merge_data(@subscription))
    @record.sender = current_person
    @record.sender_address = format_mobile(ENV['twilio_number'])
    @record.recipient = @person
    @record.recipient_address = format_mobile(@person.mobile)
    @record.delivery_status = "not sent"

    #if @record.valid? && @record.type == "SMS"
    #  unless send_sms(@record)
    #    @record.errors.add(:base, "SMS failed to send")
    #  end
    #end

    respond_to do |format|
      if @record.save
        send_sms(@record)

        format.html { redirect_to new_subscription_record_path(@subscription), notice: 'Record was successfully created.' }
        format.json { render :show, status: :created, location: @record }
      else
        format.html { render :new }
        format.json { render json: @record.errors, status: :unprocessable_entity }
      end
    end
  end

  
  # PATCH/PUT /records/1
  # PATCH/PUT /records/1.json
  def update
    respond_to do |format|
      if @record.update(record_params)
        format.html { redirect_to @record, notice: 'Record was successfully updated.' }
        format.json { render :show, status: :ok, location: @record }
      else
        format.html { render :edit }
        format.json { render json: @record.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /records/1
  # DELETE /records/1.json
  def destroy
    @record.destroy
    respond_to do |format|
      format.html { redirect_to new_subscription_record_url(@subscription), notice: 'Record was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_record
      @record = Record.find(params[:id])
    end

    def set_subscription
      @subscription = Subscription.find(params[:subscription_id])
    end

    def set_person
      @person = @subscription.person
    end

    def set_join_form
      @join_form = @subscription.join_form
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def record_params
      params.require(:record).permit(:type, :subject, :body_plain, :body_html, :delivery_status, :sender_id, :recipient_id, :recipient, :sender, :template_id, :parent_id)
    end
end