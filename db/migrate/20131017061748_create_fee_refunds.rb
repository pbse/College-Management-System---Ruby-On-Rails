class CreateFeeRefunds < ActiveRecord::Migration
  def self.up
    create_table :fee_refunds do |t|
      t.integer :finance_fee_id
      t.text :reason
      t.decimal :amount, :precision =>15, :scale => 4
      t.integer :finance_transaction_id
      t.integer :refund_rule_id
      t.integer :user_id
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :fee_refunds
  end
end
