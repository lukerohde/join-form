class AddExternalIdToPerson < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :external_id, :string
  end
end
