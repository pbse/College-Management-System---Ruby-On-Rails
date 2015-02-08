class AddBalanceColumnToFinanceFee < ActiveRecord::Migration
  def self.up
    add_column :finance_fees,:balance,:decimal,:precision =>15, :scale => 2,:default=>0
  end

  def self.down
    remove_column :finance_fees,:balance
  end
end
