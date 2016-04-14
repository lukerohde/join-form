class CreatePayments < ActiveRecord::Migration[5.0]
  def change
    create_table :payments do |t|
      t.date :date
      t.decimal :amount, precision: 8, scale: 2
      t.string :external_id

      t.timestamps
    end
  end
end
