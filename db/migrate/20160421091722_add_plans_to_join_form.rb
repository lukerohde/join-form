class AddPlansToJoinForm < ActiveRecord::Migration[5.0]
  def change
    add_column :join_forms, :plans, :json
  end
end
