class Union < Supergroup

	has_many :people
	has_many :join_forms
	
	def stripe_connected?
		stripe_access_token.present?
	end
end
