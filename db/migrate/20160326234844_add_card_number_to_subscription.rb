class AddCardNumberToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :card_number, :string
  end
end
