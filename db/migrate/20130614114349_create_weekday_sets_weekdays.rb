class CreateWeekdaySetsWeekdays < ActiveRecord::Migration
  def self.up
    create_table :weekday_sets_weekdays do |t|
      t.references :weekday
      t.references :weekday_set

      t.timestamps
    end
  end

  def self.down
    drop_table :weekday_sets_weekdays
  end
end
