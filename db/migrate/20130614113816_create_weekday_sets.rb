class CreateWeekdaySets < ActiveRecord::Migration
  def self.up
    create_table :weekday_sets do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :weekday_sets
  end
end
