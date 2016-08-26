class EmailTemplatesController < ApplicationController
  before_action :set_email_template, only: [:show, :edit, :update, :destroy]
  before_action :set_subscription, only: [:new, :edit]

  include SubscriptionsHelper
  
  # GET /email_templates
  # GET /email_templates.json
  def index
    @email_templates = EmailTemplate.filter(params.slice(:name_like))
  end

  # GET /email_templates/1
  # GET /email_templates/1.json
  def show
      redirect_to new_email_template_preview_path(@email_template)
  end 

  # GET /email_templates/new
  def new
    if params[:duplicate_email_template_id].present?
      @email_template = EmailTemplate.find(params[:duplicate_email_template_id]).dup
      @email_template.short_name = "Copy of #{@email_template.short_name}"
    else
      @email_template = EmailTemplate.new()
    end
  end

  # GET /email_templates/1/edit
  def edit
  end

  # POST /email_templates
  # POST /email_templates.json
  def create
    @email_template = EmailTemplate.new(email_template_params)

    respond_to do |format|
      if @email_template.save
        format.html { redirect_to @email_template, notice: 'Email template was successfully created.' }
        format.json { render :show, status: :created, location: @email_template }
      else
        format.html { render :new }
        format.json { render json: @email_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /email_templates/1
  # PATCH/PUT /email_templates/1.json
  def update
    respond_to do |format|
      if @email_template.update(email_template_params)
        format.html { redirect_to @email_template, notice: 'Email template was successfully updated.' }
        format.json { render :show, status: :ok, location: @email_template }
      else
        format.html { render :edit }
        format.json { render json: @email_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /email_templates/1
  # DELETE /email_templates/1.json
  def destroy
    @email_template.destroy
    respond_to do |format|
      format.html { redirect_to email_templates_url, notice: 'Email template was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_email_template
      @email_template = EmailTemplate.find(params[:id])
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
    def email_template_params
      params.require(:email_template).permit(:short_name, :subject, :body_html, :css, :body_plain, :pdf_html, :attachment, :bootsy_image_gallery_id)
    end
end
