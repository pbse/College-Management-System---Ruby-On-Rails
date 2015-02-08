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

class ApplyLeave < ActiveRecord::Base
  validates_presence_of :employee_leave_types_id, :start_date, :end_date, :reason
  belongs_to :employee
  belongs_to :employee_leave_type
  before_create :check_leave_count
  
  cattr_reader :per_page
  @@per_page = 12

  def validate
    employee_leave = EmployeeLeave.find_by_employee_leave_type_id_and_employee_id(employee_leave_types_id,employee_id)
    search = ApplyLeave.find(:all,:conditions => ["(employee_id = ? AND (approved IS NULL OR approved = ?)) AND ((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?))",employee_id,true,start_date,end_date,start_date,end_date,start_date,end_date])
    errors.add(:base, :same_range_of_date_exists) if(((search.count == 1 and is_half_day == false) or (search.count == 2 and is_half_day == true)) and new_record?)
    errors.add(:base, :reset_date_before) if(employee_leave.present? and employee_leave.reset_date.present? and employee_leave.reset_date.to_date > start_date)
  end

  def check_leave_count

    unless self.start_date.nil? or self.end_date.nil?
      errors.add_to_base:end_date_cant_before_start_date if self.end_date < self.start_date

    end
    unless self.start_date.nil? or self.end_date.nil? or self.employee_leave_types_id.nil?
      leave = EmployeeLeave.find_by_employee_id(self.employee_id, :conditions=> "employee_leave_type_id = '#{self.employee_leave_types_id}'")
      leave_required = (self.end_date.to_date-self.start_date.to_date).numerator+1
      if self.start_date.to_date < self.employee.joining_date.to_date
        errors.add_to_base :date_marked_is_before_join_date

      else
        unless leave.nil?
          if leave.leave_taken.to_f == leave.leave_count.to_f
            errors.add_to_base :you_have_already_availed

          else
            if self.is_half_day == true
              new_leave_count = (leave_required)/2
              if leave.leave_taken.to_f+new_leave_count.to_f > leave.leave_count.to_f
                errors.add_to_base :no_of_leaves_exceeded_max_allowed
              end
            else
              new_leave_count = leave_required.to_f
              if leave.leave_taken.to_f+new_leave_count.to_f > leave.leave_count.to_f
                errors.add_to_base :no_of_leaves_exceeded_max_allowed

              end
            end
          end
        else
          errors.add_to_base :no_leave_assigned_yet
        end
      end
    end
    if self.errors.present?
      return false
    else
      return true
    end
  end

  def leave_status
    if self.viewed_by_manager and self.approved
      return "approved"
    else
      return "rejected"
    end
  end
  
  def leave_days
    if start_date==end_date
      start_date.strftime "%a,%d %b %Y"
    else
      "#{start_date.strftime "%a,%d %b %Y"} to #{end_date.strftime "%a,%d %b %Y"}"
    end
  end

end
