class AddPendingToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :pending, :boolean, null: false, default: false
  end
end
