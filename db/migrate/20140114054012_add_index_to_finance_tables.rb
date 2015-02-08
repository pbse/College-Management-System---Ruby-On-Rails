class AddIndexToFinanceTables < ActiveRecord::Migration
  def self.up
      add_index :category_batches, [:finance_fee_category_id, :batch_id]
      add_index :fee_collection_batches, [:finance_fee_collection_id]
      add_index :fee_collection_batches, [:batch_id]
      add_index :fee_transactions, [:finance_fee_id, :finance_transaction_id],:name => "finance_transaction_index"
      add_index :collection_discounts, [:finance_fee_collection_id, :fee_discount_id],:name => "fee_discount_index"
      add_index :collection_particulars, [:finance_fee_collection_id, :finance_fee_particular_id],:name => "fee_particular_index"
  end

  def self.down
     remove_index :category_batches, [:finance_fee_category_id, :batch_id]
     remove_index :fee_collection_batches
     remove_index :fee_transactions,:name => "finance_transaction_index"
     remove_index :collection_discounts,:name => "fee_discount_index"
     remove_index :collection_particulars,:name => "fee_particular_index"
  end
end
