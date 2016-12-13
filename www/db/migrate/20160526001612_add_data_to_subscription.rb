class AddDataToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :data, :jsonb, null: false, default: '{}'
    add_index :subscriptions, :data, using: :gin
  end
end
