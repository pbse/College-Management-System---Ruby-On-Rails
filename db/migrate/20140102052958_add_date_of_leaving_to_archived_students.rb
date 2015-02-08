class AddDateOfLeavingToArchivedStudents < ActiveRecord::Migration
  def self.up
    add_column :archived_students, :date_of_leaving, :date
  end

  def self.down
    remove_column :archived_students, :date_of_leaving
  end
end
