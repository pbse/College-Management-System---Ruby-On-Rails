class AddReceiverTypeColumnToFeeDiscount < ActiveRecord::Migration
  def self.up
    add_column :fee_discounts,:receiver_type,:string
  end

  def self.down
    remove_column :fee_discounts,:receiver_type,:string
  end
end
