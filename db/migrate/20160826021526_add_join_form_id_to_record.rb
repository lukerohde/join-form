class AddJoinFormIdToRecord < ActiveRecord::Migration
  def change
    add_column :records, :join_form_id, :integer
  end
end
