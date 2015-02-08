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

class EmployeeLeave < ActiveRecord::Base
  belongs_to :employee_leave_type
  belongs_to :employee
  validates_numericality_of :leave_count, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :leave_taken, :greater_than_or_equal_to => 0, :allow_nil => true

  def after_initialize
    return if new_record?
    self.reset_date = reset_date || employee.joining_date.to_datetime unless(employee.nil? or employee.joining_date.nil?)
  end
end
