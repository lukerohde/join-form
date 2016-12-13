class AddStripeTokenToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :stripe_token, :string
  end
end
