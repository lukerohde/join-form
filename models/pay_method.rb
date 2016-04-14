class Application
	class PayMethod < ActiveRecord::Base
		self.table_name = "tblBank"
		self.primary_key = "MemberID"

		ignore_columns :tblBankUniqueID

		belongs_to :Person

		validates :AccountName, :AccountNo, presence: true
		validates :Expiry, presence: true, if: :credit_card?
		validates :bsb, presence: true, if: :au_bank_account?
		
		def credit_card?
			self.AccountType != 'S'
		end

		def au_bank_account?
			self.AccountType == 'S'
		end
	end
end
