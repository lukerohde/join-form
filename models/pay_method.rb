class Application
	class PayMethod < ActiveRecord::Base
		self.table_name = "tblBank"
		self.primary_key = "MemberID"

		ignore_columns :tblBankUniqueID

		belongs_to :Person
	end
end
