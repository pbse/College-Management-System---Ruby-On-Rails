class CreateCancelledFinanceTransactions < ActiveRecord::Migration
  def self.up
     create_table :cancelled_finance_transactions do |t|
      t.string     :title
      t.string     :description
      t.decimal    :amount, :precision =>15, :scale => 2
      t.boolean    :fine_included, :default => false
      t.references :category
      t.references :student
      t.references :finance_fees
      t.date       :transaction_date
      t.decimal    :fine_amount, :precision => 10, :scale => 2,:default =>0
      t.integer    :master_transaction_id, :default =>0
      t.integer    :finance_id
      t.string     :finance_type
      t.integer    :payee_id
      t.string     :payee_type
      t.string     :receipt_no
      t.string     :voucher_no
      t.integer    :school_id
      t.integer    :lastvchid
      t.string     :payment_mode
      t.text       :payment_note
      t.references :user
      t.string     :collection_name
      t.timestamps
    end
  end

  def self.down
    drop_table :cancelled_finance_transactions
  end
end
