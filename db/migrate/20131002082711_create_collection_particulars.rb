class CreateCollectionParticulars < ActiveRecord::Migration
  def self.up
    create_table :collection_particulars do |t|
      t.integer :finance_fee_collection_id
      t.integer :finance_fee_particular_id

      t.timestamps
    end
  end

  def self.down
    drop_table :collection_particulars
  end
end
