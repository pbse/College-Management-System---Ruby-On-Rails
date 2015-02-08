class CreateRefundRules < ActiveRecord::Migration
  def self.up
    create_table :refund_rules do |t|
      t.integer :finance_fee_collection_id
      t.string :name
      t.date :refund_validity
      t.decimal :refund_percentage, :precision =>15, :scale => 4
      t.integer :user_id

      t.timestamps
  end
  end

  def self.down
    drop_table :refund_rules
  end
end
