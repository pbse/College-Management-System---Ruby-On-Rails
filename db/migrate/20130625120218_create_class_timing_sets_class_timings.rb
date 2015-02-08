class CreateClassTimingSetsClassTimings < ActiveRecord::Migration
  def self.up
    create_table :class_timing_sets_class_timings do |t|
      t.references :class_timing_set
      t.references :class_timing

      t.timestamps
    end
  end

  def self.down
    drop_table :class_timing_sets_class_timings
  end
end
