module SubscriptionsHelper

	def pay_method_options(subscription)
    options_for_select(
      [
        'Credit Card',
        'Australian Bank Account',
      ], 
      subscription.pay_method
    )
  end

  def frequency_options(subscription)
    result = []
    f = subscription.join_form

    result << "Weekly - #{f.base_rate_weekly}" if f.base_rate_weekly
    result << "Fortnightly - #{f.base_rate_fortnightly}" if f.base_rate_fortnightly
    result << "Monthly - #{f.base_rate_monthly}" if f.base_rate_monthly
    result << "Quarterly - #{f.base_rate_quarterly}" if f.base_rate_quarterly
    result << "Half Yearly - #{f.base_rate_half_yearly}" if f.base_rate_half_yearly
    result << "Yearly - #{f.base_rate_yearly}" if f.base_rate_yearly
    
    current_selection = subscription.frequency || "Fortnightly"
    current_selection = result.find { |i| i.downcase.starts_with?(current_selection.downcase) }

    options_for_select(
      result, 
      current_selection
    )

  end

end
