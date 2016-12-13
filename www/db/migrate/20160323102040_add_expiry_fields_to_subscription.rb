class AddExpiryFieldsToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :expiry_month, :integer
    add_column :subscriptions, :expiry_year, :integer
  end
end
