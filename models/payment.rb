class Application
	class Payment < ActiveRecord::Base
		self.table_name = "tblTransaction"
		self.primary_key = "tblTransactionUniqueID"

		belongs_to :Person
	end
end
