class AddIndicesToTimetables < ActiveRecord::Migration
  def self.up
    add_index :timetables, [:start_date]
    add_index :timetables, [:end_date]
  end

  def self.down
    remove_index :timetables, [:start_date]
    remove_index :timetables, [:end_date]
  end
end
