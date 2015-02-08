class CreateRecordUpdates < ActiveRecord::Migration
  def self.up
    create_table :record_updates do |t|
      t.string :file_name
      t.integer  :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :timetable_swaps
  end
end
