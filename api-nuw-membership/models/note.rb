class Application
	class Note < ActiveRecord::Base
		self.table_name = "tblNote"
		self.primary_key = "tblNoteUniqueID"

		belongs_to :Person
	end
end
