class CreateTimeTableClassTimings < ActiveRecord::Migration
  def self.up
    create_table :time_table_class_timings do |t|
      t.references :batch
      t.references :timetable
      t.references :class_timing_set

      t.timestamps
    end
  end

  def self.down
    drop_table :time_table_class_timings
  end
end
