class AddSchoolIdToTables < ActiveRecord::Migration
  def self.up
    add_column :time_table_weekdays, :school_id, :integer
    add_column :class_timing_sets, :school_id, :integer
    add_column :weekday_sets, :school_id, :integer
    add_column :time_table_class_timings, :school_id, :integer
    add_column :class_timing_sets_class_timings, :school_id, :integer
    add_column :weekday_sets_weekdays, :school_id, :integer
    
  end

  def self.down
    remove_column :time_table_weekdays, :school_id
    remove_column :class_timing_sets, :school_id
    remove_column :weekday_sets, :school_id
    remove_column :time_table_class_timings, :school_id
    remove_column :class_timing_sets_class_timings, :school_id
    remove_column :weekday_sets_weekdays, :school_id
  end
end
