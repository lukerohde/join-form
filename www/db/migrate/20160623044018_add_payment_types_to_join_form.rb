class AddPaymentTypesToJoinForm < ActiveRecord::Migration
  def up
    add_column :join_forms, :credit_card_on, :boolean
    add_column :join_forms, :direct_debit_on, :boolean
    add_column :join_forms, :payroll_deduction_on, :boolean
    add_column :join_forms, :direct_debit_release_on, :boolean
		JoinForm.update_all(credit_card_on: true, direct_debit_on: true)
  end

  def down
    remove_column :join_forms, :credit_card_on
    remove_column :join_forms, :direct_debit_on	
    remove_column :join_forms, :payroll_deduction_on	
    remove_column :join_forms, :direct_debit_release_on	
  end
end
