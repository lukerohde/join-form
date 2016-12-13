class AddKeyPairToSupergroup < ActiveRecord::Migration[5.0]
  def change
    add_column :supergroups, :key_pair, :text
  end
end
