class AddDeferralOnToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :deferral_on, :boolean
  end
end
