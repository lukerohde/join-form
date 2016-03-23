class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]
  before_action :set_join_form

  # GET /subscriptions
  # GET /subscriptions.json
  def index
    @subscriptions = Subscription.all
  end

  # GET /subscriptions/1
  # GET /subscriptions/1.json
  def show
  end

  # GET /subscriptions/new
  def new
    @subscription = Subscription.new
    @subscription.person = Person.new
    @subscription.join_form = @join_form
  end

  # GET /subscriptions/1/edit
  def edit
  end

  # POST /subscriptions
  # POST /subscriptions.json
  def create
    @subscription = Subscription.new(subscription_params)
    respond_to do |format|
      if @subscription.save_with_payment
        format.html { redirect_to @subscription, notice: 'Subscription was successfully created.' }
        format.json { render :show, status: :created, location: @subscription }
      else
        format.html { render :new }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subscriptions/1
  # PATCH/PUT /subscriptions/1.json
  def update
    respond_to do |format|
      if @subscription.update(subscription_params)
        format.html { redirect_to @subscription, notice: 'Subscription was successfully updated.' }
        format.json { render :show, status: :ok, location: @subscription }
      else
        format.html { render :edit }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscriptions/1
  # DELETE /subscriptions/1.json
  def destroy
    @subscription.destroy
    respond_to do |format|
      format.html { redirect_to subscriptions_url, notice: 'Subscription was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def subscription_params
      
      if params[:subscription][:person_attributes].present?
        params[:subscription][:person_attributes][:union_id] = @join_form.union.id
        params[:subscription][:person_attributes][:authorizer_id] = @join_form.person.id
      end

      result = params.require(:subscription).permit(
        [
          :join_form_id, 
          :frequency, 
          :pay_method, 
          :account_name, 
          :account_number, 
          :expiry_month,
          :expiry_year,
          :stripe_token, 
          :ccv, 
          :bsb, 
          person_attributes: [
              :first_name,
              :last_name,
              :gender,
              :email,
              :mobile,
              :address1, 
              :address2,
              :suburb,
              :state,
              :postcode,
              :union_id,
              :authorizer_id,
              :id
            ]
        ])
    end

    def set_join_form
      id = params[:join_form_id] || params.dig(:subscription, :join_form_id) 
      
      if (Integer(id) rescue nil)
        @join_form = @union.join_forms.find(id)
      else
        @join_form = @union.join_forms.where("short_name ilike ?",id).first
      end
    end
end
