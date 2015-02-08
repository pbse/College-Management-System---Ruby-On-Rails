class AddSoftDeleteForPayrollCategory < ActiveRecord::Migration
  def self.up
    add_column :payroll_categories,:is_deleted,:boolean, :default => false
  end

  def self.down
    remove_column :payroll_categories,:is_deleted
  end
end
