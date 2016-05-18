class Subscription < ApplicationRecord

  belongs_to :person
  belongs_to :subscription
  belongs_to :join_form
  accepts_nested_attributes_for :person
  has_many :payments, autosave: true
  
  validates :person, :join_form, presence: true
  validate :subscription_must_be_complete, if: :address_saved?
  validate :address_must_be_complete, if: :contact_details_saved?
  validate :pay_method_must_be_complete, if: :subscription_saved?

  encrypt_with_public_key :card_number, :ccv, :account_number, :bsb, 
    :symmetric => :never,
    :base64 => true,
    :key_pair => :get_key_pair,
    :deferred_encryption => true

  def get_key_pair
    self.join_form.union.key_pair
  end

  before_validation :set_token, on: [:create]
  
  def set_token
    self.token = SecureRandom.urlsafe_base64(16) # equivalent of 128 bit key
  end

  def address_saved?
  	person.present? && person.address1_was.present? && person.suburb_was.present? && person.state_was.present? && person.postcode_was.present? 
  end

  def address_present?
    person.present? && person.address1.present? && person.suburb.present? && person.state.present? && person.postcode.present?
  end

  def contact_details_saved?
    (person.present? && person.email_was.present? && person.first_name_was.present? && person.first_name.downcase != "unknown") 
  end

  def subscription_saved?
  	(frequency_was.present? && plan_was.present?)
  end

  def subscription_present?
    frequency.present? && plan.present?
  end

  def pay_method_saved?
    # can have an old stripe_token
  	errors.empty? && (stripe_token_was.present? || (bsb_was.present? && account_number_was.present?) || pay_method == "-") || @skip_validation
  end

  def bsb_valid?
    # e.g. 123-123 or 123123
  	bsb.decrypt =~ /^\d{3}-?\d{3}$/ || bsb.decrypt == "*encrypted*"
  end

  def account_number_valid?
  	account_number.decrypt =~ /^\d+$/ || account_number.decrypt == "*encrypted*"
  end

  def subscription_must_be_complete
    return if @skip_validation

    errors.add(:plan,I18n.translate("subscriptions.errors.not_blank")) if plan.blank?
    errors.add(:frequency,I18n.translate("subscriptions.errors.not_blank")) if frequency.blank?
  end

  def address_must_be_complete
    return if @skip_validation

  	if person
  		person.errors.add(:address1,I18n.translate("subscriptions.errors.not_blank")) unless person.address1.present?
    	person.errors.add(:suburb,I18n.translate("subscriptions.errors.not_blank")) unless person.suburb.present?
    	person.errors.add(:state,I18n.translate("subscriptions.errors.not_blank")) unless person.state.present?
    	person.errors.add(:postcode,I18n.translate("subscriptions.errors.not_blank")) unless person.postcode.present?
  		errors.add(:base,I18n.translate("subscriptions.errors.complete_address")) unless person.address_valid?
  	end
  end

  def pay_method_must_be_complete
  	return if @skip_validation
    case pay_method
    when "-"
      #pay_method = pay_method_was
  	when "CC"
  		errors.add(:card_number,I18n.translate("subscriptions.errors.credit_card")) unless stripe_token.present?
  	when "AB"
      errors.add(:bsb,I18n.translate("subscriptions.errors.bsb") ) unless bsb_valid?
  		errors.add(:account_number,I18n.translate("subscriptions.errors.account_number") ) unless account_number_valid?
  	else
  		errors.add(:pay_method,I18n.translate("subscriptions.errors.pay_method") )
  	end
  end

  def save_without_validation!
    @skip_validation = true
    result = save!
    @skip_validation = false
    result
  end

  def step
    return :thanks if pay_method_saved?
  	return :pay_method if subscription_saved?
  	return :subscription if address_saved?
  	return :address if contact_details_saved?
  	:contact_details
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
    result = self.join_form.fee(self.join_form.max_frequency) if result == 0 # This is probably stupid - defaults the user to the minimum amount chargeable if they have a different frequency
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
end
