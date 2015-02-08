class AddAttachmentsImageToRedactorUpload < ActiveRecord::Migration
  def self.up
    add_column :redactor_uploads, :image_file_name, :string
    add_column :redactor_uploads, :image_content_type, :string
    add_column :redactor_uploads, :image_file_size, :integer
    add_column :redactor_uploads, :image_updated_at, :datetime
  end

  def self.down
    remove_column :redactor_uploads, :image_file_name
    remove_column :redactor_uploads, :image_content_type
    remove_column :redactor_uploads, :image_file_size
    remove_column :redactor_uploads, :image_updated_at
  end
end
