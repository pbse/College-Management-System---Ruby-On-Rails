class AddBatchColumnToFeeDiscount < ActiveRecord::Migration
  def self.up
    add_column :fee_discounts,:batch_id,:integer
    add_column :fee_discounts,:is_deleted,:boolean,:default=>false
  end

  def self.down
    remove_column :fee_discounts,:batch_id,:integer
    remove_column :fee_discounts,:is_deleted,:boolean,:default=>false
  end
end
