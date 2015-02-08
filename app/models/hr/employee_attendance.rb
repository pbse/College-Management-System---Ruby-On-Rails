#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class EmployeeAttendance < ActiveRecord::Base
  validates_presence_of :employee_id,:employee_leave_type_id, :reason,:attendance_date
  validates_uniqueness_of :employee_id, :scope=> :attendance_date
  belongs_to :employee
  belongs_to :employee_leave_type
  before_save :validate

  def validate
    unless attendance_date.nil? or employee.nil? or employee_id.nil? or employee_leave_type_id.nil? or reason.nil?
      if self.attendance_date.to_date < self.employee.joining_date.to_date
        errors.add(:employee_attendance,:date_marked_is_earlier_than_joining_date)
      end
      employee_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(employee.id, employee_leave_type.id)
      errors.add(:employee_leave_type_id, :is_already_taken) if (employee_leave.leave_count == employee_leave.leave_taken and changed.include? :employee_leave_type_id)
      errors.add(:attendance_date, :cannot_mark_attendance_before_reset_date) if(employee_leave.present? and employee_leave.reset_date.present? and employee_leave.reset_date.to_date > attendance_date)
    end
  end
  
end
