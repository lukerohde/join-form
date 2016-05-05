class Union < Supergroup

	has_many :people
	has_many :join_forms

	attr_accessor :old_passphrase
	attr_accessor :passphrase
	attr_accessor :passphrase_confirmation
	validate :passphrase_ok?, if: :passphrase_present?

	def passphrase_present?
		passphrase.present?
	end

	def passphrase_ok?
		errors.add :old_passphase, "is incorrect" unless confirm_passphrase(old_passphrase)
		errors.add :passphrase, "should be at least 40 characters" if passphrase.length < 40
		errors.add :passphrase_confirmation, "doesn't match" unless passphrase = passphrase_confirmation
		unless errors.any?
			set_key_pair
		end
	end

	def set_key_pair
		self.key_pair = get_key_pair(passphrase)
	end

	def get_key_pair(passphrase)

 		key = OpenSSL::PKey::RSA.new(2048)
		public_key = key.public_key.to_pem
		private_key = key.to_pem(OpenSSL::Cipher::Cipher.new('des3'), passphrase)
		private_key + public_key

	end

	def confirm_passphrase(passphrase)
		result = true
		if self.key_pair
			result = OpenSSL::PKey::RSA.new(self.key_pair, passphrase).private?
		end
		result
	end

	def stripe_connected?
		stripe_access_token.present?
	end
end
