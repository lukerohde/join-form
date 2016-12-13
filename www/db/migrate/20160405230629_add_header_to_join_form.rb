class AddHeaderToJoinForm < ActiveRecord::Migration[5.0]
  def change
    add_column :join_forms, :header, :text
  end
end
