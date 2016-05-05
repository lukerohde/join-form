class AddPersonToJoinForm < ActiveRecord::Migration
  def change
    add_reference :join_forms, :person, index: true, foreign_key: true
  end
end
