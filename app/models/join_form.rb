class JoinForm < ApplicationRecord
	belongs_to :union
	belongs_to :person
	has_many :subscriptions
	
	validates :short_name, :person, :union, presence: true
	validates :base_rate_id, presence: true
	validates :base_rate_weekly, numericality: { allow_blank: true }	
	validate :is_authorized?

	after_initialize :set_defaults
	
	def set_defaults

		self.css ||= <<-CSS.gsub(/^\t{3}/,'')
			/* background colour */
			body {
			 background-color: #fee;
			}

			/* heading colors */
			h1,h2,h3 {
			  color: #D33;
			}

			/* label colours */
			.form-group > label {
			  color:#555555;
			}

			/* control colours */
			.form-control {
			  background-color: #fff;
			  color: #555555;
			}
		CSS

	end

	def authorizer=(person)
		@authorizer = person
	end

	def is_authorized?(person = nil)
		@authorizer = person unless person.blank?
		
		if @authorizer.blank?
			errors.add(:authorizer, "hasn't be specified, so this update cannot be made.")
			return
		end

		if @authorizer.union.short_name != ENV['OWNER_UNION']
			if self.union_id != @authorizer.union_id
				errors.add(:union, "is not your union so this assignment is not authorized.")
			end 

			if self.person.present? && self.person.union_id != @authorizer.union_id
				errors.add(:person, "is not a colleague from your union so this assignment is not authorized.")
			end
		end
	end
end
