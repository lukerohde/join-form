class SubscriptionPresenter
  attr_reader :subscription

  def initialize(subscription)
    @subscription = subscription
  end

  def join_form
    @subscription.join_form
  end

  def deduction_date_shown?
    @subscription.deduction_date_required?
  end

  def deduction_date_options
    subscription.available_deduction_dates.map do |date|
      [I18n.localize(date, format: :with_day), "#{date}"]
    end
  end

  def deduction_date_default
    subscription.deduction_date || deduction_date_options.first
  end

  def frequency_shown?
    @subscription.pay_method != "PRD"
  end

  def frequency_options
    %w(W F M Q H Y).select(&method(:frequency_available?)).map do |freq|
      ["#{friendly_frequency(freq)} - #{friendly_fee(freq)}", freq]
    end
  end

  def frequency_default
    frequency_options.find { |_, f| f == (subscription.frequency.upcase || "F") } || frequency_options.first
  end

  def friendly_signature_date
    if @subscription.signature_vector.present?
      result = @subscription.signature_date.try(:strftime, "%d / %B / %Y")
      result ||= "Signed but not dated"
    else
      result = Date.today.strftime("%d / %B / %Y")
    end
  end

  def pay_method_options
    result = []

    if subscription.has_existing_pay_method?
      result << [I18n.t('subscriptions.pay_method.edit.use_existing_bank_account'), "-"] if subscription.pay_method == "AB"
      result << [I18n.t('subscriptions.pay_method.edit.use_existing_credit_card'), "-"] if subscription.pay_method == "CC"
    end
    #result << [t('subscriptions.pay_method.edit.use_existing'), "-"] if subscription.has_existing_pay_method?
    result << [I18n.t('subscriptions.pay_method.edit.credit_card'), 'CC'] if subscription.join_form.credit_card_on
    result << [I18n.t('subscriptions.pay_method.edit.au_bank_account'), 'AB'] if subscription.join_form.direct_debit_on
    result << [I18n.t('subscriptions.pay_method.edit.payroll_deduction'), 'PRD'] if subscription.join_form.payroll_deduction_on
    result << [I18n.t('subscriptions.pay_method.edit.direct_debit_release'), 'ABR'] if subscription.join_form.direct_debit_release_on

    result
  end

  def pay_method_default
    methods = subscription.join_form.pay_methods << "-"
    result = subscription.pay_method || "AB"  # made AB the default since more people choose it and it'll work without JS

    result = "-" if subscription.has_existing_pay_method? && # has partial payment details
                    ["AB", "CC"].include?(subscription.pay_method) && # they are CC or AB
                    methods.include?(subscription.pay_method)  # the form supports their pay method

    result = methods[0] unless methods.include?(result)
    result
  end

  def deduction_date_label
    if subscription.has_existing_pay_method?
      I18n.t("subscriptions.form.next_deduction_date")
    else
      I18n.t("subscriptions.form.first_deduction_date")
    end
  end

  def submit_label
    submit_label = I18n.t("subscriptions.form.submit_next")
    if subscription.miscellaneous_saved?
      if subscription.has_existing_pay_method?
        submit_label =  I18n.t("subscriptions.form.submit_renew")
      else
        submit_label =  I18n.t("subscriptions.form.submit_join")
      end
    end

    submit_label
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


  private
  def frequency_available?(frequency)
    join_form.fee(frequency).nonzero?
  end


end
