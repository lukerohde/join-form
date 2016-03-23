class Subscription < ApplicationRecord
  belongs_to :person
  belongs_to :join_form
  accepts_nested_attributes_for :person
  
  validates :person, :join_form, :frequency, presence: true

 	def save_with_payment
	  if valid?
	  	customer = Stripe::Customer.create(description: person.email, card: stripe_token)
	    person.stripe_token = customer.id
	    charge = Stripe::Charge.create(amount: 500, currency: 'AUD', description: join_form.description, customer: person.stripe_token)
	    save!
	  end
	rescue Stripe::InvalidRequestError => e
	  logger.error "Stripe error while creating customer: #{e.message}"
	  errors.add :base, "There was a problem with your credit card."
	  false
	end
end
