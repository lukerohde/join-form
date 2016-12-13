class AddFinancialDateToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :financial_date, :date
  end
end
