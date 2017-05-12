class AddDeductionDateOnToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :deduction_date_on, :boolean, default: true, null: false
  end
end
