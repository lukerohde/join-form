class AddUnionToJoinForm < ActiveRecord::Migration
  def change
    add_reference :join_forms, :union, index: true
  	add_foreign_key :join_forms, :supergroups, column: :union_id
  end
end
