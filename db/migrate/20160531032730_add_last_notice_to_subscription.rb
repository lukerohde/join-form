class AddLastNoticeToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :last_notice, :datetime
  end
end
