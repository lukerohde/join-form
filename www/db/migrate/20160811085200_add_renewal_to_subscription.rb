class AddRenewalToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :renewal, :boolean
  end
end
