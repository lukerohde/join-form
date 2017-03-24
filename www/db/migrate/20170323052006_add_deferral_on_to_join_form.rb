class AddDeferralOnToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :deferral_on, :boolean, default: false, null: false
  end
end
