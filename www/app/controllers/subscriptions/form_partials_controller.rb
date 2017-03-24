class Subscriptions::FormPartialsController < SubscriptionsController
  before_action :set_id_param
  before_action :set_subscription
  before_action :set_join_form

  # GET /en/union/join_form/subscription_token/pay_method
  def pay_method
    render partial: "subscriptions/pay_method/edit_pay_method", layout: false
  end

  # GET /en/union/join_form/subscription_token/frequency
  def frequency
    render partial: "subscriptions/pay_method/edit_frequency", layout: false
  end

  # GET /en/union/join_form/subscription_token/deduction_date
  def deduction_date
    render partial: "subscriptions/pay_method/edit_deduction_date", layout: false
  end

  private
  def set_id_param
    params[:id] = params[:subscription_id]
  end
end
