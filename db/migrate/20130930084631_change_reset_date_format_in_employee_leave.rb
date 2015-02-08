class ChangeResetDateFormatInEmployeeLeave < ActiveRecord::Migration
  def self.up
    change_column :employee_leaves, :reset_date, :datetime
  end

  def self.down
    change_column :employee_leaves, :reset_date, :date
  end
end
