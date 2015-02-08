class AddWeekdaySetIdToBatches < ActiveRecord::Migration
  def self.up
    add_column :batches, :weekday_set_id, :integer
  end

  def self.down
    remove_column :batches, :weekday_set
  end
end
