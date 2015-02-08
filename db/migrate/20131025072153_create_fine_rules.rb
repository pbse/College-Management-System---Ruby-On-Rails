class CreateFineRules < ActiveRecord::Migration
  def self.up
    create_table :fine_rules do |t|
      t.integer :fine_id
      t.integer :fine_days
      t.decimal :fine_amount, :precision =>10, :scale => 4
      t.boolean :is_amount
      t.integer :user_id
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :fine_rules
  end
end
