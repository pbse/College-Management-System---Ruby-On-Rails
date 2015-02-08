class AddUserColumnToFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions,:user_id,:integer
  end

  def self.down
    remove_column :finance_transactions,:user_id,:integer
  end
end
