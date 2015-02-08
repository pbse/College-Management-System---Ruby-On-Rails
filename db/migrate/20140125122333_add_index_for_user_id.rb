class AddIndexForUserId < ActiveRecord::Migration
  def self.up
    add_index :students, [:user_id]
    add_index :employees, [:user_id]
  end

  def self.down
    remove_index :students, [:user_id]
    remove_index :employees, [:user_id]
  end
end
