class SmsTemplatesController < ApplicationController
  include SubscriptionsHelper
    
  before_action :set_sms_template, only: [:show, :edit, :update, :destroy]
  before_action :set_subscription, only: [:new, :edit]

  
  # GET /sms_templates
  # GET /sms_templates.json
  def index
    @sms_templates = SmsTemplate.all
  end

  def show
      redirect_to new_sms_template_preview_path(@sms_template)
  end 

  # GET /email_templates/new
  def new
    if params[:duplicate_sms_template_id].present?
      @sms_template = SmsTemplate.find(params[:duplicate_sms_template_id]).dup
      @sms_template.short_name = "Copy of #{@sms_template.short_name}"
    else
      @sms_template = SmsTemplate.new()
    end
  end

  # GET /sms_templates/1/edit
  def edit
  end

  # POST /sms_templates
  # POST /sms_templates.json
  def create
    @sms_template = SmsTemplate.new(sms_template_params)

    respond_to do |format|
      if @sms_template.save
        format.html { redirect_to @sms_template, notice: 'Sms template was successfully created.' }
        format.json { render :show, status: :created, location: @sms_template }
      else
        format.html { render :new }
        format.json { render json: @sms_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sms_templates/1
  # PATCH/PUT /sms_templates/1.json
  def update
    respond_to do |format|
      if @sms_template.update(sms_template_params)
        format.html { redirect_to @sms_template, notice: 'Sms template was successfully updated.' }
        format.json { render :show, status: :ok, location: @sms_template }
      else
        format.html { render :edit }
        format.json { render json: @sms_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sms_templates/1
  # DELETE /sms_templates/1.json
  def destroy
    @sms_template.destroy
    respond_to do |format|
      format.html { redirect_to sms_templates_url, notice: 'Sms template was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sms_template
      @sms_template = SmsTemplate.find(params[:id])
    end

    def set_subscription
      @subscription = Subscription.find_by_id(params[:subscription_id])
      @subscription ||= Subscription.last
      nuw_end_point_reload(@subscription)
      @data = merge_data(@subscription)
      @prev = Subscription.where(['id < ?', @subscription.id]).last
      @next = Subscription.where(['id > ?', @subscription.id]).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def sms_template_params
      params.require(:sms_template).permit(:short_name, :body)
    end
end
