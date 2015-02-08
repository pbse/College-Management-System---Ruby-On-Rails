class AddCreatedAtToApplyLeaves < ActiveRecord::Migration
  def self.up
    add_column :apply_leaves, :created_at, :datetime
    add_column :apply_leaves, :updated_at, :datetime
  end

  def self.down
    remove_column :apply_leaves, :updated_at
    remove_column :apply_leaves, :created_at
  end
end
