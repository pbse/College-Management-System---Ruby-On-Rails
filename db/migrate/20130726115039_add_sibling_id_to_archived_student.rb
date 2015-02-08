class AddSiblingIdToArchivedStudent < ActiveRecord::Migration
  def self.up
    add_column :archived_students,:sibling_id,:integer
   end

  def self.down
    remove_column :archived_students,:sibling_id
  end
end
