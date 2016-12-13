class AddForeignKeysToPayment < ActiveRecord::Migration[5.0]
  def change
    add_reference :payments, :person, foreign_key: true
    add_reference :payments, :subscription, foreign_key: true
  end
end
