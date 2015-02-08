class CreateClassTimingSets < ActiveRecord::Migration
  def self.up
    create_table :class_timing_sets do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :class_timing_sets
  end
end
