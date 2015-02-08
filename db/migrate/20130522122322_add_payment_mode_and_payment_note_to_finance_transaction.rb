class AddPaymentModeAndPaymentNoteToFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions, :payment_mode, :string
    add_column :finance_transactions, :payment_note, :text
  end

  def self.down
    remove_column :finance_transactions, :payment_note
    remove_column :finance_transactions, :payment_mode
  end
end
