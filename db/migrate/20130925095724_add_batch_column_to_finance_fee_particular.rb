class AddBatchColumnToFinanceFeeParticular < ActiveRecord::Migration
  def self.up
    add_column :finance_fee_particulars,:receiver_id,:integer
    add_column :finance_fee_particulars,:receiver_type,:string
    add_column :finance_fee_particulars,:batch_id,:integer
  end

  def self.down
    remove_column :finance_fee_particulars,:receiver_id,:integer
    remove_column :finance_fee_particulars,:receiver_type,:string
    remove_column :finance_fee_particulars,:batch_id,:integer
  end
end
