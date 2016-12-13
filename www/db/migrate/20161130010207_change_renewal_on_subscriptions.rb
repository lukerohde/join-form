class ChangeRenewalOnSubscriptions < ActiveRecord::Migration
  def up
    execute "update subscriptions set renewal=false where renewal is null"
    change_column :subscriptions, :renewal, :boolean, default: false, null: false
  end

  def down
  	change_column :subscriptions, :renewal, :boolean
  end
end
