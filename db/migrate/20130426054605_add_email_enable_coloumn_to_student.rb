class AddEmailEnableColoumnToStudent < ActiveRecord::Migration
  def self.up
    add_column :students, :is_email_enabled, :boolean,:default=>true
  end

  def self.down
    remove_column :students, :is_email_enabled
  end
end
