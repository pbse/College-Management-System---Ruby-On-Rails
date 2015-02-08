class AddSiblingIdToStudent < ActiveRecord::Migration
  def self.up
    add_column :students,:sibling_id,:integer
   end

  def self.down
    remove_column :students,:sibling_id
  end
end
