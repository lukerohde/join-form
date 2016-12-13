class AddSignatureRequiredToJoinForm < ActiveRecord::Migration
  def change
    add_column :join_forms, :signature_required, :boolean, default: false
  end
end
