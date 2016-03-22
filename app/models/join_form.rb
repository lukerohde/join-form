class JoinForm < ApplicationRecord
	belongs_to :union
	belongs_to :person
	
	validates :short_name, :person, :union, presence: true
	validates :base_rate_weekly, numericality: { allow_blank: true }	
	validate :is_authorized?
	
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
