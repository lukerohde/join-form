class RemoveLastNoticeFromSubscription < ActiveRecord::Migration
  def change
    remove_column :subscriptions, :last_notice, :datetime
  end
end
