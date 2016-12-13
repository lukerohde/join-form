class ChangeSchemaInJoinForm < ActiveRecord::Migration
  def up
    remove_index :join_forms, :schema
    change_column :join_forms, :schema, :text
  end

  def down
    #change_column :join_forms, :schema, :jsonb
    execute "alter table join_forms alter schema set data type jsonb using schema::jsonb"
    add_index :join_forms, :schema, using: :gin
  end
end
