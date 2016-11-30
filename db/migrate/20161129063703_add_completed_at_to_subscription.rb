class AddCompletedAtToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :completed_at, :datetime
  end
end
