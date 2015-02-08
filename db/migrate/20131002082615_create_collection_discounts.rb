class CreateCollectionDiscounts < ActiveRecord::Migration
  def self.up
    create_table :collection_discounts do |t|
      t.integer :finance_fee_collection_id
      t.integer :fee_discount_id

      t.timestamps
    end
  end

  def self.down
    drop_table :collection_discounts
  end
end
