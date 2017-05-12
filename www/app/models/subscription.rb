require 'open3'
class Subscription < ApplicationRecord

  belongs_to :person
  belongs_to :subscription
  belongs_to :join_form
  accepts_nested_attributes_for :person
  has_many :payments, autosave: true, dependent: :destroy

  validates :person, :join_form, presence: true

  validate :address_completed,        if: :address_must_be_complete?
  validate :miscellaneous_completed,  if: :miscellaneous_must_be_complete?
  validate :pay_method_completed,     if: :pay_method_must_be_complete?

  delegate :external_id, to: :person, allow_nil: true
  delegate :schema_data, to: :join_form, allow_nil: true
  scope :with_mobile, -> { joins(:person).where.not(people: { mobile: [nil, ''] })}
  scope :with_email, -> { joins(:person).where.not(Person.arel_table[:email].matches('%@unknown.com'))}

  serialize :data, HashSerializer

  encrypt_with_public_key :card_number, :ccv, :account_number, :bsb,
    :symmetric => :never,
    :base64 => true,
    :key_pair => :get_key_pair,
    :deferred_encryption => true

  mount_uploader :signature_image, SignatureUploader
  before_save :generate_signature_image
  before_save :set_data_if_blank
  before_save :set_completed_at
  before_validation :set_token, on: [:create]
  after_initialize :set_frequency_if_blank
  after_initialize :set_pay_method_if_blank

  # def check_step
  #   binding.pry
  #   step
  # end

  def step
    return :thanks if errors.count == 0 && self.completed_at.present? && pay_method_saved? && (miscellaneous_saved? || !miscellaneous_required?) && (address_saved? || !address_required?) && contact_details_saved?
    return :pay_method if (miscellaneous_saved? || !miscellaneous_required?) && (address_saved? || !address_required?) && contact_details_saved?
    return :miscellaneous if (address_saved? || !address_required?) && contact_details_saved? && miscellaneous_required?
    return :address if contact_details_saved?
    :contact_details
  end

  # TODO get this working so we can replace step with custom step order
  # :thanks also needs errors.count == 0 && self.completed_at.present?
  def step_new(order = [:contact_details, :address, :miscellaneous, :pay_method, :thanks])
    check_order = order.reverse

    check_order.each do |step|
      reachable = order.take_while(&step.method(:!=)).all? do |prev_step|
        send("#{prev_step}_saved?") && !send("#{prev_step}_required?")
      end
      required = step == order.last ? (errors.count == 0 && self.completed_at.present?) : send("#{step}_required?")

      return step if (required && reachable) || (step == order.first)
    end
  end

  # ??
  def step_by_unsaved_state
  end

  def address_saved?
    person.present? && person.address1_was.present? && person.suburb_was.present? && person.state_was.present? && person.postcode_was.present?
  end

  def address_present?
    person.present? && person.address1.present? && person.suburb.present? && person.state.present? && person.postcode.present?
  end

  def contact_details_saved?
    (person.present? && person.email_was.present? && !Person.temporary_email?(person.email_was) && person.first_name_was.present? && !Person.temporary_first_name?(person.first_name_was))
  end

  def subscription_saved?
    puts "DEPRECATION WARNING: Use `miscellaneous_saved?` instead of `subscription_saved?`"
    miscellaneous_saved?
  end

  # Has the current data been persisted?
  def miscellaneous_saved?
    custom_columns_saved = true
    (self.schema_data[:columns]||[]).each do |column|
      custom_columns_saved = false if (data_was||{})[column].blank?
    end

    custom_columns_saved
  end

  def subscription_present?
    puts "DEPRECATION WARNING: Use `miscellaneous_present?` instead of `subscription_present?`"
    miscellaneous_present?
  end

  def miscellaneous_present?
    (self.schema_data[:columns] || []).any? { |col| data[col].present? }
    # frequency.present? && plan.present?
  end

  def has_existing_pay_method?
    partial_account_number_was.present? || (partial_card_number_was.present? && stripe_token.present?)
  end

  def set_country_code(location)
    self.country_code ||= location
    if self.country_code == nil || ["", "RD"].include?(self.country_code)
     self.country_code = ENV['ADDRESS_REQUIRED_COUNTRY_CODES'].split(',').first # use first as default
    end
  end


  def contact_details_required?
    true
  end

  # Address is required if the user is determined to be from Australia or the
  # U.S. (because of a large number of U.S. proxy users)
  def address_required?
    #TODO Test wizard when address is not required
    self.join_form.address_on && (self.country_code.nil? || ENV['ADDRESS_REQUIRED_COUNTRY_CODES'].split(',').include?(self.country_code)) # address not required outside of australia, but on by default
  end

  def subscription_required?
    puts "DEPRECATION WARNING: Use `miscellaneous_required?` instead of `subscription_required?`"
    miscellaneous_required?
  end

  # Placeholder - will be based on something like join_form.has_custom_questions?
  def miscellaneous_required?
    join_form.has_custom_questions?
  end

  # Placeholder
  def pay_method_required?
    true
  end

  def pay_method_saved?
    #errors.empty? && (stripe_token_was.present? || (bsb_was.present? && account_number_was.present?) || pay_method == "-") || @skip_validation
    # TODO why am I somethings using _was, prevent welcome message being sent when matching an existing person
    # When a signature is already saved and I'm OOP
    (errors.empty? &&
      (
        (self.pay_method == "AB" && self.join_form.direct_debit_on && has_existing_pay_method?) ||
        (self.pay_method == "CC" && self.join_form.credit_card_on && has_existing_pay_method?) ||
        (self.pay_method == "PRD" && self.join_form.payroll_deduction_on) ||
        (self.pay_method == "ABR" && self.join_form.direct_debit_release_on)
      ) && (!self.join_form.signature_required || self.signature_vector.present?)
    ) || @skip_validation
    # frequency_was.present? && plan_was.present?
  end

  def save_without_validation!
    @skip_validation = true
    result = save_without_timestamps # do not set updated_at when the user isn't saving (api save)
    @skip_validation = false
    result
  end

  def discount
    dues = (self.payments.sum(:amount)||0)
    dues > establishment_fee ? establishment_fee : dues
  end

  def establishment_fee
    self.join_form.base_rate_establishment || 0
  end

  def total
    (establishment_fee - discount)
  end

  def reoccurring_fee
    result = self.join_form.fee(self.frequency)
    result = self.join_form.fee(self.join_form.max_frequency) if (result||0) == 0 # This is probably stupid - defaults the user to the minimum amount chargeable if they have a different frequency
    # TODO add javascript to update the page, if the user changes the frequency when on the payment method step
    result
  end

  def first_payment
    if self.total < 0.01
      self.reoccurring_fee
    else
      self.total
    end
  end

  def update_with_payment(params, union)
    assign_attributes(params)
    if valid?
      customer = Stripe::Customer.create({description: person.email, card: stripe_token} , {stripe_account: union.stripe_user_id})
      person.stripe_token = customer.id

      stripe_amount = (self.first_payment * 100).round(0).to_i

      if stripe_amount > 0
        charge = Stripe::Charge.create({amount: stripe_amount, currency: 'AUD', description: join_form.description, customer: person.stripe_token}, {stripe_account: union.stripe_user_id})
        self.payments << Payment.new(date: Date.today, amount: (stripe_amount / 100.0).round(2), person_id: self.person.id)
      end

      save!
    end
  rescue Stripe::CardError => e
    logger.error "Stripe error while creating customer: #{e.message}"
    errors.add :base, "#{I18n.translate('subscriptions.errors.payment_gateway_card_error')}: #{e.message}"
    false
  rescue Stripe::InvalidRequestError => e
    logger.error "Stripe error while creating customer: #{e.message}"
    errors.add :base, "#{I18n.translate('subscriptions.errors.payment_gateway_error')}: #{e.message}."
    false
  end

  def source=(val)
    write_attribute(:source, val) if self.source.blank? # prevent overwriting
  end

  def update_from_end_point(payload)
    @skip_validation = true

    subscription_payload = payload.except(:person_attributes, :payments_attributes)
    person_payload = payload[:person_attributes]
    payments_payload = payload[:payments_attributes]

    subscription_payload.each do |k,v|
      self.send("#{k}=", v) unless v.blank?
    end

    person_payload.each do |k,v|
      self.person.send("#{k}=", v) unless v.blank?

      #if k == :authorizer_id
      #  self.person.authorizer_id = v unless v.blank? # can't use write_attribute since its not a database attribute
      #else
      #  self.person.write_attribute(k,v) unless v.blank?
      #end
    end

    # either add or update payment, assumes eager loading, n^2 nastiness, to avoid multiple database hits
    payments_payload.each do |payment_payload|
      payment_payload.except!(:id).merge!(person_id: self.person.id)
      found = false
      self.payments.each do |p|
        if p.external_id == payment_payload[:external_id].to_s
          found = true
          p.assign_attributes(payment_payload) # TODO make sure this works
        end
      end
      unless found
        self.payments.build(payment_payload)
      end
    end

    save!
    @skip_validation = false
  end

  def deferral_dates
    Array(Date.today..Date.today.next_year - 1).reject(&:weekend?)
  end

  # Options start from next day for AB pay method, and exclude weekends
  # Options start from next day for ABR pay method, and exclude weekends
  # Options start from today for the CC pay method, and exclude weekends
  # Blank array for PRD pay method, & quarterly and yearly frequencies
  # All options extend past their 'min' date by frequency - 1
  def available_deduction_dates
    return deferral_dates if join_form.deferral_on
    return [] unless deduction_date_required?

    min_date = case pay_method
    when "CC" then Date.today
    when "AB", "ABR" then Date.today.next_day
    end

    max_date = case frequency
    when "W" then (min_date || Date.today) + 6
    when "F" then (min_date || Date.today) + 13
    when "M"
      d1 = (min_date || Date.today)
      d2 = d1.next_month
      d2 - (d2.mday == d1.mday ? 1 : 0)
    end

    return [] if [min_date, max_date].include?(nil)

    Array(min_date..max_date).reject(&:weekend?)
  end

  def deduction_date_required?
    join_form.deduction_date_on && (join_form.deferral_on || (self.pay_method != "PRD" && ["W", "F", "M"].include?(self.frequency)))
  end

  private
  def set_completed_at
    # called after validation
    # everything is saved or we are passing validation when setting the pay_method
    if step == :thanks || (step == :pay_method && errors.count == 0 && !@skip_validation)
      self.completed_at = Time.now
      self.pending = false
    else
      self.completed_at = nil
    end
    true # prevent halt of callback chain
  end

  def set_data_if_blank
    self.data = {} if data.blank? # set a default, when blank, because of a possible AR/jsonb bug
  end

  def set_frequency_if_blank
    self.frequency ||= "F"
  end

  def set_pay_method_if_blank
    self.pay_method ||= "AB"
  end

  def get_key_pair
    self.join_form.union.key_pair
  end

  def set_token
    self.token = SecureRandom.urlsafe_base64(16) # equivalent of 128 bit key
  end

  def generate_signature_image
    if self.signature_vector.present? && self.signature_vector != self.signature_vector_was
      instructions = JSON.parse(signature_vector).map { |h| "line #{h['mx'].to_i},#{h['my'].to_i} #{h['lx'].to_i},#{h['ly'].to_i}" } * ' '
      tempfile = Tempfile.new(["signature", '.png'])
      Open3.popen3("convert -size 298x98 xc:transparent -stroke blue -draw @- #{tempfile.path}") do |input, output, error|
        input.puts instructions
      end
      self.signature_date = Date.today
      self.signature_image = File.open(tempfile)
    end
  end

  def save_without_timestamps
    return self.save! if self.new_record?

    class << self
      def record_timestamps; false; end
    end

    begin
      self.save!
    ensure
      class << self
       remove_method :record_timestamps
      end
    end
  end

  # Step is on or after address and it is required
  def address_must_be_complete?
    [:address, :miscellaneous, :pay_method, :thanks].include?(step) && address_required?
  end

  # Validate address
  def address_completed
    return if @skip_validation
    return unless address_required?

    if person
      person.errors.add(:address1,I18n.translate("subscriptions.errors.not_blank")) unless person.address1.present?
      person.errors.add(:suburb,I18n.translate("subscriptions.errors.not_blank")) unless person.suburb.present?
      person.errors.add(:state,I18n.translate("subscriptions.errors.not_blank")) unless person.state.present?
      person.errors.add(:postcode,I18n.translate("subscriptions.errors.not_blank")) unless person.postcode.present?
      errors.add(:base,I18n.translate("subscriptions.errors.complete_address")) unless person.address_valid?
    end
  end

  # Step is on or after miscellaneous and it is required
  def miscellaneous_must_be_complete?
    [:miscellaneous, :pay_method, :thanks].include?(step) && miscellaneous_required?
  end

  # Validate miscellaneous
  def miscellaneous_completed
    return if @skip_validation

    # validate presence of custom columns
    (self.schema_data[:columns]||[]).each do |column|
      errors.add(column,I18n.translate("subscriptions.errors.not_blank")) if data[column].blank?
    end
  end

  # Step is on or after :pay_method and it is required
  def pay_method_must_be_complete?
    [:pay_method, :thanks].include?(step) && pay_method_required?
  end

  # Validate the pay method step, including the :plan, :pay_method, :frequency,
  # :deduction_date, and :signature_vector attributes
  def pay_method_completed
    return if @skip_validation

    errors.add(:plan,I18n.translate("subscriptions.errors.not_blank")) if plan.blank?
    errors.add(:frequency,I18n.translate("subscriptions.errors.not_blank")) if frequency.blank?

    validate_pay_method()
    validate_deduction_date()

    if join_form.signature_required && signature_vector.blank?
      errors.add(:signature_vector, I18n.translate("subscriptions.errors.not_blank"))
    end
  end

  def validate_pay_method
    case pay_method
    # not a super elegant place to put this, but I don't want to save a dash, and I don't want to validate existing details (because they're not persisted).
    when "-" then self.restore_pay_method!
    when "CC"
      errors.add(:card_number,I18n.translate("subscriptions.errors.credit_card")) unless stripe_token.present?
    when "AB"
      errors.add(:bsb,I18n.translate("subscriptions.errors.bsb")) unless bsb_valid?
      errors.add(:account_number,I18n.translate("subscriptions.errors.account_number")) unless account_number_valid?
    when "ABR"
    when "PRD"
    else
      errors.add(:pay_method,I18n.translate("subscriptions.errors.pay_method"))
    end
  end

  # Nil value is OK for some pay methods and frequencies. These pay methods
  # and frequencies will have an empty array of available_deduction_dates.
  def validate_deduction_date
    if deduction_date_required?
      if deduction_date.nil?
        error_msg = I18n.t("subscriptions.errors.not_blank")
        errors.add(:deduction_date, error_msg) unless available_deduction_dates.empty?
      else
        error_msg = I18n.t("subscriptions.errors.out_of_bounds")
        errors.add(:deduction_date, error_msg) unless available_deduction_dates.include?(deduction_date)
      end
    end
  end

  def bsb_valid?
    # e.g. 123-123 or 123123
    bsb.decrypt =~ /^\d{3}-?\d{3}$/ #&& bsb.decrypt != "*encrypted*"
  end

  def account_number_valid?
    account_number.decrypt =~ /^\d+$/ #&& account_number.decrypt != "*encrypted*"
  end

  # def subscription_must_be_complete?
  #   puts "DEPRECATION WARNING: Use `miscellaneous_must_be_complete?` instead of `subscription_must_be_complete?`"
  #   miscellaneous_must_be_complete?
  # end
  # def subscription_completed
  #   puts "DEPRECATION WARNING: Use `miscellaneous_completed` instead of `subscription_completed`"
  #   miscellaneous_completed
  # end
end
