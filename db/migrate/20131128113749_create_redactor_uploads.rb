class CreateRedactorUploads < ActiveRecord::Migration
  def self.up
    create_table :redactor_uploads do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :redactor_uploads
  end
end
