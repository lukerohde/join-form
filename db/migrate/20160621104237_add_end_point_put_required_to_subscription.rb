class AddEndPointPutRequiredToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :end_point_put_required, :boolean, default: false
  end
end
