class RecordBatchesController < ApplicationController
  before_action :set_record_batch, only: [:show, :edit, :update, :destroy]
  before_action :set_subscriptions, only: [:new, :create]
  before_action :set_join_form
  skip_before_action :verify_authenticity_token, if: :api_request?
  before_action :verify_hmac, if: :api_request?

  include RecordsHelper
  include SubscriptionsHelper

  # GET /record_batches
  # GET /record_batches.json
  def index
    @record_batches = RecordBatch.all
  end

  # GET /record_batches/1
  # GET /record_batches/1.json
  def show
  end

  # GET /record_batches/new
  def new
    @record_batch = RecordBatch.new
    @record_batch.join_form = JoinForm.find_by_short_name(params[:join_form_id])
    @record_batch.name = "Messages from #{current_person.display_name} #{Date.today.iso8601}"
  end

  # POST /record_batches
  # POST /record_batches.json
  def create

    @record_batch = RecordBatch.new(record_batch_params)
    @record_batch.join_form ||= @join_form
    @record_batch.sender = current_person
    @record_batch.sender_sms_address = format_mobile(ENV['twilio_number'])
    @record_batch.sender_email_address = reply_to(current_person.email)

    if @record_batch.sms_template.present?
      # SMS Message Setup
      body = @record_batch.sms_template.body
      @sms_subscriptions.each do |s|
        s.join_form = @record_batch.join_form if @record_batch.join_form.present?
        data = merge_data(s)

        record = Record.new(
          type: 'SMS',
          sender: @record_batch.sender,
          sender_address: @record_batch.sender_sms_address, 
          recipient: s.person, 
          recipient_address: format_mobile(s.person.mobile),
          body_plain: Liquid::Template.parse(body).render(data),
          message_id: "<#{SecureRandom.uuid}@#{ENV['mailgun_domain']}>",
          join_form: s.join_form
        )
        @record_batch.records << record
      end
    end

    if @record_batch.email_template.present?
      # EMAIL Message Setup
      # TODO DRY THIS UP WITH EMAIL_TEMPLATE_MAILER & RECORDS CONTROLLER
      email_template = @record_batch.email_template
      subject_template = email_template.subject
      body_plain_template = email_template.body_plain
      body_html_template = email_template.body_html
      css =  email_template.css

      @email_subscriptions.each do |s|
        s.join_form = @record_batch.join_form if @record_batch.join_form.present?
        data = merge_data(s)

        subject = Liquid::Template.parse(subject_template).render(data)
        body_plain = Liquid::Template.parse(body_plain_template).render(data) if body_plain_template.present?
        body_html_css = nil      
        if body_html_template.present?
          body_html = Liquid::Template.parse(body_html_template).render(data)
          body_html_css = Roadie::Document.new(body_html)
          body_html_css.add_css(css)
          body_html_css.url_options = {host: ENV['mailgun_host'], protocol: "https"}
          body_html_css = body_html_css.transform
        end

        # Remarking this out because single thread rails can't grab pdf from page inside a controller
        #if email_template.pdf_html.present?
        #  pdf_url = pdf_email_template_preview_url(email_template, subscription_id: s.token, locale: locale) 
        #  file_name = "#{s.external_id || s.token}.pdf"
        #  begin
        #    # TODO make this filename configurable
        #    attachments[file_name] = WickedPdf.new.pdf_from_url(pdf_url)
        #  rescue
        #    subject += " - couldn't attach #{file_name}"
        #  end
        #end

        record = Record.new(
          type: 'Email',
          sender: @record_batch.sender,
          sender_address: @record_batch.sender_email_address, 
          recipient: s.person, 
          recipient_address: s.person.email,
          subject: subject, 
          body_plain: body_plain,
          body_html: body_html_css,
          message_id: "<#{SecureRandom.uuid}@#{ENV['mailgun_domain']}>",
          join_form: s.join_form
        )
        @record_batch.records << record
      end
    end

    #binding.pry
    respond_to do |format|
      if @record_batch.save
        SendRecordBatchesJob.perform_later(@record_batch.id)

        format.html { redirect_to union_join_form_record_batch_path(@record_batch.join_form.union, @record_batch.join_form, @record_batch), notice: 'Record batch was successfully created.' }
        format.json { render :show, status: :created, location: @record_batch }
      else
        format.html { render :new }
        format.json { render json: @record_batch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /record_batches/1
  # DELETE /record_batches/1.json
  def destroy
    @record_batch.destroy
    respond_to do |format|
      format.html { redirect_to union_join_form_record_batches_path(@union, @record_batch.join_form), notice: 'Record batch was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_record_batch
      @record_batch = RecordBatch.find(params[:id])
    end

    def set_subscriptions
      ids = (params[:subscription_ids] ||"").split(',')
      @subscriptions = Subscription.where(id: ids)
      @sms_subscriptions = @subscriptions.with_mobile
      @email_subscriptions = @subscriptions.with_email
    end

    def set_join_form
      id = params[:join_form_id] || params.dig(:record_batch, :join_form_id) || @record_batch.join_form.id
    
      if (Integer(id) rescue nil)
        @join_form = @union.join_forms.find(id)
      else
        @join_form = @union.join_forms.where("short_name ilike ?",id).first if @join_form.nil?
      end
    end


    # Never trust parameters from the scary internet, only allow the white list through.
    def record_batch_params
      params.require(:record_batch).permit(:name, :email_template_id, :sms_template_id, :join_form_id)
    end
end
