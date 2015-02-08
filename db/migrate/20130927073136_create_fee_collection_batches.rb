class CreateFeeCollectionBatches < ActiveRecord::Migration
  def self.up
    create_table :fee_collection_batches do |t|
      t.integer :finance_fee_collection_id
      t.integer :batch_id

      t.timestamps
    end
  end

  def self.down
    drop_table :fee_collection_batches
  end
end
