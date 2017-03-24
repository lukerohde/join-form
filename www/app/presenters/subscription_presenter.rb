class SubscriptionPresenter
  attr_reader :subscription, :join_form

  def initialize(subscription)
    @subscription = subscription
    @join_form = @subscription.join_form
  end

  def deduction_date_options
    subscription.available_deduction_dates.map do |date|
      [I18n.localize(date, format: :with_day), "#{date}"]
    end
  end

  def deduction_date_default
    deduction_date_options.first
  end

  def frequency_options
    %w(W F M Q H Y).select(&method(:frequency_available?)).map do |freq|
      ["#{friendly_frequency(freq)} - #{friendly_fee(freq)}", freq]
    end
  end

  def frequency_default
    frequency_options.find { |_, f| f == (subscription.frequency.upcase || "F") } || frequency_options.first
  end

  def pay_method_options
    options = []
    options << [I18n.t('subscriptions.pay_method.edit.use_existing'), "-"] if subscription.has_existing_pay_method?
    options << [I18n.t('subscriptions.pay_method.edit.credit_card'), 'CC'] if join_form.credit_card_on
    options << [I18n.t('subscriptions.pay_method.edit.au_bank_account'), 'AB'] if join_form.direct_debit_on
    options << [I18n.t('subscriptions.pay_method.edit.payroll_deduction'), 'PRD'] if join_form.payroll_deduction_on
    options << [I18n.t('subscriptions.pay_method.edit.direct_debit_release'), 'ABR'] if join_form.direct_debit_release_on

    options
  end

  def pay_method_default
    methods = join_form.pay_methods << "-"
    result = subscription.has_existing_pay_method? && ["AB", "CC"].include?(subscription.pay_method) ? "-" : (subscription.pay_method || "AB") # made this the default since more people choose it and it'll work without JS
    result = methods[0] unless methods.include?(result)

    result
  end

  private
  def frequency_available?(frequency)
    join_form.fee(frequency).nonzero?
  end

  def friendly_frequency(freq)
    case freq
    when "W" then I18n.t('subscriptions.subscription.edit.weekly')
    when "F" then I18n.t('subscriptions.subscription.edit.fortnightly')
    when "M" then I18n.t('subscriptions.subscription.edit.monthly')
    when "Q" then I18n.t('subscriptions.subscription.edit.quarterly')
    when "H" then I18n.t('subscriptions.subscription.edit.half_yearly')
    when "Y" then I18n.t('subscriptions.subscription.edit.yearly')
    end
  end

  def friendly_fee(freq)
    fee = join_form.fee(freq)
    if fee.present? && fee > 0
      ActionController::Base.helpers.number_to_currency(fee, locale: I18n.locale)
    else
      ""
    end
  end
end
