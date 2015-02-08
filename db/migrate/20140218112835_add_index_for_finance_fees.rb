class AddIndexForFinanceFees < ActiveRecord::Migration
  def self.up
    add_index  :finance_fees, [:batch_id]
  end

  def self.down
    remove_index  :finance_fees, [:batch_id]
  end
end
