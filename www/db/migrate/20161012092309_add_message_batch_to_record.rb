class AddMessageBatchToRecord < ActiveRecord::Migration
  def change
    add_column :records, :record_batch_id, :int
  end
end
