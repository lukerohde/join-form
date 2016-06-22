class AddUpfrontPaymentFieldsToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :up_front_payment, :decimal, precision: 8, scale: 2
      
    add_column :subscriptions, :first_recurrent_payment_date, :date
  end
end
