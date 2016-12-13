class AddCallbackUrlToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :callback_url, :string
  end
end
