class AddPartialAccountFieldsToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :partial_account_number, :string
    add_column :subscriptions, :partial_card_number, :string
    add_column :subscriptions, :partial_bsb, :string
  end
end
