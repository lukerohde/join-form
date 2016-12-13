class CreateJoinForms < ActiveRecord::Migration
  def change
    create_table :join_forms do |t|
      t.string :short_name
      t.text :description
      t.text :css
      
      t.decimal :base_rate_establishment, precision: 6, scale: 2
			t.decimal :base_rate_weekly, precision: 6, scale: 2
			t.decimal :base_rate_fortnightly, precision: 6, scale: 2
			t.decimal :base_rate_monthly, precision: 6, scale: 2
      t.decimal :base_rate_quarterly, precision: 6, scale: 2
      t.decimal :base_rate_half_yearly, precision: 6, scale: 2
      t.decimal :base_rate_yearly, precision: 6, scale: 2
      
      t.timestamps null: false
    end
  end
end
