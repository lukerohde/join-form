class AddPdfToEmailTemplate < ActiveRecord::Migration
  def change
    add_column :email_templates, :pdf_html, :text
  end
end
