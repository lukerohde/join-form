class Subscription < ApplicationRecord
  belongs_to :person
  belongs_to :join_form
  accepts_nested_attributes_for :person
  
  validates :person, :join_form, presence: true
  validates :frequency, :plan, presence: true, if: :address_saved?
  validate :address_must_be_complete, if: :contact_details_saved?
  validate :pay_method_must_be_complete, if: :subscription_saved?

  def address_saved?
  	person.present? && person.address1_was.present? && person.suburb_was.present? && person.state_was.present? && person.postcode_was.present?
  end

  def contact_details_saved?
  	person.present? && person.email_was.present? && person.first_name_was.present?
  end

  def subscription_saved?
  	frequency_was.present? && plan_was.present?
  end

  def pay_method_saved?
  	stripe_token_was.present? or (bsb_was.present? && account_number_was.present?)
  end

  def bsb_valid?
  	bsb =~ /^\d{3}-?\d{3}$/ # e.g. 123-123 or 123123
  end

  def account_number_valid?
  	account_number =~ /^\d+$/
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
	  	
	  if valid?
	  	customer = Stripe::Customer.create({description: person.email, card: stripe_token} , {stripe_account: union.stripe_user_id})
	    person.stripe_token = customer.id
	    charge = Stripe::Charge.create({amount: 500, currency: 'AUD', description: join_form.description, customer: person.stripe_token}, {stripe_account: union.stripe_user_id})
	    save!
	  end
	rescue Stripe::CardError => e
		logger.error "Stripe error while creating customer: #{e.message}"
		errors.add :base, "Your card was declined."
	  false
	rescue Stripe::InvalidRequestError => e
	  logger.error "Stripe error while creating customer: #{e.message}"
	  errors.add :base, "There was a problem with your credit card."
	  false
	end
end
