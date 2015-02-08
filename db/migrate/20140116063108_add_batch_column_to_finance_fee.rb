class AddBatchColumnToFinanceFee < ActiveRecord::Migration
  def self.up
    add_column :finance_fees, :batch_id,:integer
  end

  def self.down
    remove_column :finance_fees, :batch_id
  end
end
