class AddSourceToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :source, :string
  end
end
