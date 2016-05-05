class AddBaseRateIdToJoinForm < ActiveRecord::Migration[5.0]
  def change
    add_column :join_forms, :base_rate_id, :string
  end
end
