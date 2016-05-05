class AddTokenToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :token, :string
  end
end
