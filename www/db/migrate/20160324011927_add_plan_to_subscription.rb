class AddPlanToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :plan, :string
  end
end
