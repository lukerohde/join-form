class AddDeductionDateToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :deduction_date, :date
  end
end
