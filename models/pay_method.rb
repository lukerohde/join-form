class Application
	class PayMethod < ActiveRecord::Base
		self.table_name = "tblBank"
		self.primary_key = "MemberID"

		ignore_columns :tblBankUniqueID

		belongs_to :Person

		validates :AccountName, :AccountNo, presence: true
		validates :Expiry, presence: true, if: :credit_card?
		validates :bsb, presence: true, if: :au_bank_account?
		validate :invalidated
		validate :format

		def credit_card?
			self.AccountType != 'S'
		end

		def au_bank_account?
			self.AccountType == 'S'
		end

		def invalidated
			unless self.InvalidationDate.nil?
				self.errors.add :base, "these bank details have been marked as invalid by #{self.InvalidationUser} on #{self.InvalidationDate}" 
			end
		end

		def format
			# credit card numbers with Xs in them are not valid
			if credit_card? && self.AccountNo.gsub(/[^\d]/, '').length != 16
				self.errors.add :base, "credit card number does not contain 16 digits" 
			end
			if credit_card? && !(self.Expiry =~ /^\d{4}$/ || self.Expiry =~ /^\d{1,2}[\/-]\d{2}$/)
				self.errors.add :base, "expiry date is poorly formatted" 
			end
		end
	end
end
