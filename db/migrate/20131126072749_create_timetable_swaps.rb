class CreateTimetableSwaps < ActiveRecord::Migration
  def self.up
    create_table :timetable_swaps do |t|
      t.date :date
      t.references :timetable_entry
      t.references :employee
      t.references :subject

      t.timestamps
    end
  end

  def self.down
    drop_table :timetable_swaps
  end
end
