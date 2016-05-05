class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.string :title
      t.string :attachment # for profile pics
      
      t.string :address1
      t.string :address2
      t.string :suburb
      t.string :state
      t.string :postcode
      t.string :gender

      t.string :mobile
      #t.string :email # added by devise later
      
      t.timestamps null: false
    end
  end
end
