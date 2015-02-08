class AddBatchColumnToFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions,:batch_id,:integer
    add_column :cancelled_finance_transactions,:batch_id,:integer
  end

  def self.down
    remove_column :finance_transactions,:batch_id,:integer
    remove_column :cancelled_finance_transactions,:batch_id,:integer
  end
end
