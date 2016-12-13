class RemovePlanDataFromSubscription < ActiveRecord::Migration
  def change
    remove_column :subscriptions, :plan_data, :json
  end
end
