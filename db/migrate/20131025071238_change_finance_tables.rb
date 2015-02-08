class ChangeFinanceTables < ActiveRecord::Migration
  def self.up
    #change_column :applicants, :amount, :decimal,:precision =>12, :scale => 4
    change_column :cancelled_finance_transactions, :amount, :decimal,:precision =>15, :scale => 4
    change_column :cancelled_finance_transactions, :fine_amount, :decimal,:precision =>10, :scale => 4
    change_column :fee_collection_discounts, :discount, :decimal, :precision => 15, :scale => 4
    change_column :fee_collection_particulars, :amount, :decimal, :precision => 12, :scale => 4
    change_column :fee_discounts, :discount, :decimal, :precision => 15, :scale => 4
    change_column :finance_donations, :amount, :decimal, :precision => 15, :scale => 4
    change_column :finance_fee_particulars, :amount, :decimal, :precision => 15, :scale => 4
    change_column :finance_fee_structure_elements, :amount, :decimal, :precision => 15, :scale => 4
    change_column :finance_fees, :balance, :decimal, :precision => 15, :scale => 4
#    change_column :finance_transaction_triggers, :percentage, :decimal, :precision => 8, :scale => 2
    change_column :finance_transactions, :amount, :decimal, :precision => 15, :scale => 4
    change_column :finance_transactions, :fine_amount, :decimal, :precision => 10, :scale => 4
    change_column :subjects, :amount, :decimal, :precision => 15, :scale => 4
    change_column :subject_amounts, :amount, :decimal, :precision => 15, :scale => 4
  end

  def self.down
#    change_column :applicants, :amount, :decimal,:precision =>12, :scale => 2
#    change_column :cancelled_finance_transactions, :amount, :decimal,:precision =>15, :scale => 2
#    change_column :cancelled_finance_transactions, :fine_amount, :decimal,:precision =>10, :scale => 2
#    change_column :fee_collection_discounts, :discount, :decimal, :precision => 15, :scale => 2
#    change_column :fee_collection_particulars, :amount, :decimal, :precision => 12, :scale => 2
#    change_column :fee_discounts, :discount, :decimal, :precision => 15, :scale => 2
#    change_column :finance_donations, :amount, :decimal, :precision => 15, :scale => 2
#    change_column :finance_fee_particulars, :amount, :decimal, :precision => 15, :scale => 2
#    change_column :finance_fee_structure_elements, :amount, :decimal, :precision => 15, :scale => 2
#    change_column :finance_fees, :balance, :decimal, :precision => 15, :scale => 2
#    change_column :finance_transaction_triggers, :percentage, :decimal, :precision => 8, :scale => 2
#    change_column :finance_transactions, :amount, :decimal, :precision => 15, :scale => 2
#    change_column :finance_transactions, :fine_amount, :decimal, :precision => 10, :scale => 2
#    change_column :subjects, :amount, :decimal, :precision => 15, :scale => 2
#    change_column :subject_amounts, :amount, :decimal, :precision => 10, :scale => 0
  end
end
