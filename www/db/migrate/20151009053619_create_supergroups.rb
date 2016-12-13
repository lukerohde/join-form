class CreateSupergroups < ActiveRecord::Migration
  def change
    create_table :supergroups do |t|
      t.string :name
      t.string :type
      t.string :www
      t.string :logo
      t.string :short_name
      
      t.timestamps null: false
    end
  end
end
