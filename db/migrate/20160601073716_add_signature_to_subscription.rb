class AddSignatureToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :signature_vector, :string
    add_column :subscriptions, :signature_image, :string
  end
end
