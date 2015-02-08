class CreateFines < ActiveRecord::Migration
  def self.up
    create_table :fines do |t|
      t.string :name
      t.boolean :is_deleted ,:default => false
      t.integer :user_id
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :fines
  end
end
