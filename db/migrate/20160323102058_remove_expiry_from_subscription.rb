class RemoveExpiryFromSubscription < ActiveRecord::Migration[5.0]
  def change
  	remove_column :subscriptions, :expiry, :string
  end
end
