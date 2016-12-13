class AddStripeToSupergroup < ActiveRecord::Migration
  def change
    add_column :supergroups, :stripe_access_token, :string
    add_column :supergroups, :stripe_refresh_token, :string
    add_column :supergroups, :stripe_publishable_key, :string
    add_column :supergroups, :stripe_user_id, :string
  end
end
