class AddSchemaToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :schema, :jsonb, null: false, default: '{}'
    add_index :join_forms, :schema, using: :gin
  end
end
