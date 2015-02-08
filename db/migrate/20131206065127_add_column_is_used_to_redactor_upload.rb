class AddColumnIsUsedToRedactorUpload < ActiveRecord::Migration
  def self.up
      add_column :redactor_uploads,:is_used,:boolean, :default => false
  end

  def self.down
      remove_column :redactor_uploads,:is_used
  end
end
