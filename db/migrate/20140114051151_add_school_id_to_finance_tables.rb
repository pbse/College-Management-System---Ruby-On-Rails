class AddSchoolIdToFinanceTables < ActiveRecord::Migration
  def self.up
    add_column :category_batches, :school_id,:integer
    add_column :fee_collection_batches, :school_id,:integer
    add_column :fee_transactions, :school_id,:integer
    add_column :collection_discounts, :school_id,:integer
    add_column :collection_particulars, :school_id,:integer
    add_column :refund_rules, :school_id,:integer
  end

  def self.down
    remove_column :category_batches, :school_id,:integer
    remove_column :fee_collection_batches, :school_id,:integer
    remove_column :fee_transactions, :school_id,:integer
    remove_column :collection_discounts, :school_id,:integer
    remove_column :collection_particulars, :school_id,:integer
    remove_column :refund_rules, :school_id,:integer
  end
end
