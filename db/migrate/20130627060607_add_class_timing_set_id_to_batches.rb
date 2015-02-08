class AddClassTimingSetIdToBatches < ActiveRecord::Migration
  def self.up
    add_column :batches, :class_timing_set_id, :integer
  end

  def self.down
    remove_column :batches, :class_timing_set_id
  end
end
