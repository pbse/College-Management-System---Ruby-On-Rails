class AddEmailEnableColoumnToArchivedStudent < ActiveRecord::Migration
  def self.up
    add_column :archived_students, :is_email_enabled, :boolean,:default=>true
  end

  def self.down
    remove_column :archived_students, :is_email_enabled
  end
end
