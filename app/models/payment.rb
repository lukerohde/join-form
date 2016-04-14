class Payment < ApplicationRecord
	belongs_to :person
	belongs_to :subscription
end
