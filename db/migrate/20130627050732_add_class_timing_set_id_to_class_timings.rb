class AddClassTimingSetIdToClassTimings < ActiveRecord::Migration
  def self.up
    add_column :class_timings, :class_timing_set_id, :integer
  end

  def self.down
    remove_column :class_timings, :class_timing_set_id
  end
end
