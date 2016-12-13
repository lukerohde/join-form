class AddCountryCodeToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :country_code, :string
  end
end
