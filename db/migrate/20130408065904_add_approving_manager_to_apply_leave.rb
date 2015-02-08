class AddApprovingManagerToApplyLeave < ActiveRecord::Migration
  def self.up
    add_column :apply_leaves, :approving_manager, :integer
  end

  def self.down
    remove_column :apply_leaves, :approving_manager
  end
end
