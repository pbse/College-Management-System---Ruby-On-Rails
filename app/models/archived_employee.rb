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

class ArchivedEmployee < ActiveRecord::Base
  belongs_to  :employee_category
  belongs_to  :employee_position
  belongs_to  :employee_grade
  belongs_to  :employee_department
  belongs_to  :user
  belongs_to  :nationality, :class_name => 'Country'
  belongs_to :user
  belongs_to  :reporting_manager,:class_name => "User"
  has_many    :archived_employee_bank_details
  has_many    :archived_employee_additional_details
  before_save :status_false

  def status_false
    unless self.status==0
      self.status=0
    end
  end

  def image_file=(input_data)
    return if input_data.blank?
    self.photo_filename     = input_data.original_filename
    self.photo_content_type = input_data.content_type.chomp
    self.photo_data         = input_data.read
  end


  has_attached_file :photo,
    :styles => {
    :thumb=> "100x100#",
    :small  => "150x150>"},
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension"

  def full_name
    "#{first_name} #{middle_name} #{last_name}"
  end

  def find_experience_years
    exp_years = self.experience_year
    date = self.created_at.to_date
    total_current_exp_days = (date-self.joining_date).to_i
    current_years = total_current_exp_days/365
    unless self.joining_date > date
      return exp_years.nil? ? current_years : exp_years+current_years
    else
      return exp_years.nil? ? 0 : exp_years
    end
  end

  def find_experience_months    
    exp_months = self.experience_month
    date = self.created_at.to_date
    total_current_exp_days = (date-self.joining_date).to_i
    rem_days = total_current_exp_days%365
    current_months = rem_days/30
    unless self.joining_date > date
      return exp_months.nil? ? current_months : exp_months+current_months
    else
      return exp_months.nil? ? 0 : exp_months
    end
  end

  def self.former_employees_details(parameters)
    sort_order=parameters[:sort_order]
    former_employee=parameters[:former_employee]
    unless former_employee.nil?
      if sort_order.nil?
        former_employees=ArchivedEmployee.all(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.created_at" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:created_at=>former_employee[:from].to_date.beginning_of_day..former_employee[:to].to_date.end_of_day}},:order=>'first_name ASC')
      else
        former_employees=ArchivedEmployee.all(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.created_at" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:created_at=>former_employee[:from].to_date.beginning_of_day..former_employee[:to].to_date.end_of_day}},:order=>sort_order)
      end
    else
      if sort_order.nil?
        former_employees=ArchivedEmployee.all(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.created_at" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:created_at=> Date.today.beginning_of_day..Date.today.end_of_day}},:order=>'first_name ASC')
      else
        former_employees=ArchivedEmployee.all(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.created_at" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:created_at=> Date.today.beginning_of_day..Date.today.end_of_day}},:order=>sort_order)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('employee_id') }","#{t('joining_date') }","#{t('leaving_date') }","#{t('department')}","#{t('position')}","#{t('manager')}","#{t('gender')}"]
    data << col_heads
    former_employees.each_with_index do |obj,i|
      col=[]
      col << "#{i+1}"
      col << "#{obj.full_name}"
      col << "#{obj.employee_number}"
      col << "#{obj.joining_date}"
      col << "#{obj.created_at.to_date}"
      col << "#{obj.department_name}"
      col << "#{obj.emp_position}"
      col << "#{obj.manager_first_name} #{obj.manager_last_name}"
      col << "#{obj.gender.downcase=='m'? t('m') : t('f')}"
      col=col.flatten
      data << col
    end
    return data
  end
  
end
