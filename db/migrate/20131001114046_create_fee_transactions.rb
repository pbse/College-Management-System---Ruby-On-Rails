class CreateFeeTransactions < ActiveRecord::Migration
  def self.up
    create_table :fee_transactions do |t|
      t.integer :finance_fee_id
      t.integer :finance_transaction_id

      t.timestamps
    end
  end

  def self.down
    drop_table :fee_transactions
  end
end
