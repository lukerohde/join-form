class TranslateJoinForm < ActiveRecord::Migration
  def self.up
    JoinForm.create_translation_table!({
      :description => :text,
      :page_title => :text,
      :schema => :text, 
      :header => :text,
      :footer => :text,
      :css => :text,
      :wysiwyg_header => :text, 
      :wysiwyg_footer => :text
    }, {
      :migrate_data => true
    })
  end

  def self.down
    JoinForm.drop_translation_table! :migrate_data => true
  end
end
