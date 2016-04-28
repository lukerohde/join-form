class AddPlanDataToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :plan_data, :json
  end
end
