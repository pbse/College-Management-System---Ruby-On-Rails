class CreateTimeTableWeekdays < ActiveRecord::Migration
  def self.up
    create_table :time_table_weekdays do |t|
      t.references :batch
      t.references :timetable
      t.references :weekday_set

      t.timestamps
    end
  end

  def self.down
    drop_table :time_table_weekdays
  end
end
