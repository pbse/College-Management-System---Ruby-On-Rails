class AddTransactionIdToMonthlyPayslip < ActiveRecord::Migration
  def self.up
    add_column :monthly_payslips,:finance_transaction_id,:integer
  end

  def self.down
    remove_column :monthly_payslips,:finance_transaction_id
  end
end
