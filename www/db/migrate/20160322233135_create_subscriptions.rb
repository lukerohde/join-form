class CreateSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :subscriptions do |t|
      t.references :person, foreign_key: true
      t.references :join_form, foreign_key: true
      t.string :frequency
      t.string :pay_method
      t.string :account_name
      t.string :account_number
      t.string :expiry
      t.string :ccv
      t.string :bsb

      t.timestamps
    end
  end
end
