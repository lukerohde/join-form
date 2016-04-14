class Subscription < ApplicationRecord

  belongs_to :person
  belongs_to :subscription
  belongs_to :join_form
  accepts_nested_attributes_for :person
  has_many :payments, autosave: true
  
  validates :person, :join_form, presence: true
  validates :frequency, :plan, presence: true, if: :address_saved?
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
  	person.present? && person.address1_was.present? && person.suburb_was.present? && person.state_was.present? && person.postcode_was.present? && !@skip_validation
  end

  def address_present?
    person.present? && person.address1.present? && person.suburb.present? && person.state.present? && person.postcode.present?
  end

  def contact_details_saved?
  	person.present? && person.email_was.present? && person.first_name_was.present? && !@skip_validation
  end

  def subscription_saved?
  	frequency_was.present? && plan_was.present? && !@skip_validation
  end

  def subscription_present?
    frequency.present? && plan.present?
  end

  def pay_method_saved?
  	stripe_token_was.present? or (bsb_was.present? && account_number_was.present?) && !@skip_validation
  end

  def bsb_valid?
  	bsb.decrypt =~ /^\d{3}-?\d{3}$/ # e.g. 123-123 or 123123
  end

  def account_number_valid?
  	account_number.decrypt =~ /^\d+$/
  end

  def address_must_be_complete
  	if person
  		person.errors.add(:address1, "You must provide an address1") unless person.address1.present?
    	person.errors.add(:suburb, "You must provide an suburb") unless person.suburb.present?
    	person.errors.add(:state, "You must provide an state") unless person.state.present?
    	person.errors.add(:postcode, "You must provide an postcode") unless person.postcode.present?
  		errors.add(:base, "You must complete your address") unless person.address_valid?
  	end
  end

  def pay_method_must_be_complete
  	case pay_method
  	when "Credit Card"
  		errors.add(:card_number, "couldn't be validated by our payment gateway.  Please try again.") unless stripe_token.present?
  	when "Australian Bank Account"
      errors.add(:bsb, "must be properly formatted BSB e.g. 123-123") unless bsb_valid?
  		errors.add(:account_number, "must be properly formatted e.g. 123456") unless account_number_valid?
  	else
  		errors.add(:pay_method, "must be specified")
  	end
  end


  def step?
  	return :thanks if pay_method_saved?
  	return :pay_method if subscription_saved?
  	return :subscription if address_saved?
  	return :address if contact_detail_saved?
  	:contact_detail
  end

  
 	def update_with_payment(params, union)
	  assign_attributes(params)
	  amount = 5.00
	  if valid?
	  	customer = Stripe::Customer.create({description: person.email, card: stripe_token} , {stripe_account: union.stripe_user_id})
	    person.stripe_token = customer.id
	    charge = Stripe::Charge.create({amount: (amount * 100).round(0), currency: 'AUD', description: join_form.description, customer: person.stripe_token}, {stripe_account: union.stripe_user_id})
	    self.payments << Payment.new(date: Date.today, amount: amount.round(2), person_id: self.person.id)
      save!
	  end
	rescue Stripe::CardError => e
		logger.error "Stripe error while creating customer: #{e.message}"
		errors.add :base, "#{e.message}"
	  false
	rescue Stripe::InvalidRequestError => e
	  logger.error "Stripe error while creating customer: #{e.message}"
	  errors.add :base, "There was a problem with your credit card: #{e.message}."
	  false
	end


  def update_from_end_point(payload)
    @skip_validation = true
      
    subscription_payload = payload.except(:person_attributes, :payments_attributes)
    person_payload = payload[:person_attributes]
    payments_payload = payload[:payments_attributes]

    subscription_payload.each do |k,v|
      self.write_attribute(k,v) unless v.blank?
    end

    person_payload.each do |k,v|
      if k == :authorizer_id
        self.person.authorizer_id = v unless v.blank? # can't use write_attribute since its not a database attribute
      else
        self.person.write_attribute(k,v) unless v.blank?
      end
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
  end
end
