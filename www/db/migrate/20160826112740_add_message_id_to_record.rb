class AddMessageIdToRecord < ActiveRecord::Migration
  def change
    add_column :records, :message_id, :string
  end
end
