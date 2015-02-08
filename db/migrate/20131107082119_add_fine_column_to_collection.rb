class AddFineColumnToCollection < ActiveRecord::Migration
  def self.up
    add_column :finance_fee_collections,:fine_id,:integer
  end

  def self.down
    remove_column :finance_fee_collections,:fine_id,:integer
  end
end
