class AddSignatureDateToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :signature_date, :date
  end
end
