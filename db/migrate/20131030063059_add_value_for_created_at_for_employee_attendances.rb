class AddValueForCreatedAtForEmployeeAttendances < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute("update employee_attendances set created_at= attendance_date where created_at is NULL;")
    ActiveRecord::Base.connection.execute("update employee_attendances set updated_at= attendance_date where updated_at is NULL;")
  end

  def self.down
  end
end
