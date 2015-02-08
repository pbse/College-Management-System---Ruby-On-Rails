class CreateCategoryBatches < ActiveRecord::Migration
  def self.up
    create_table :category_batches do |t|
      t.integer :finance_fee_category_id
      t.integer :batch_id

      t.timestamps
    end
  end

  def self.down
    drop_table :category_batches
  end
end
