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

class Employee < ActiveRecord::Base

  attr_accessor_with_default(:biometric_id) {BiometricInformation.find_by_user_id(user_id).try(:biometric_id)}
  
  belongs_to  :employee_category
  belongs_to  :employee_position
  belongs_to  :employee_grade
  belongs_to  :employee_department
  belongs_to  :nationality, :class_name => 'Country'
  belongs_to  :home_country, :class_name => 'Country'
  belongs_to  :office_country, :class_name => 'Country'
  belongs_to  :user
  belongs_to  :reporting_manager,:class_name => "User"
  
  has_many    :employees_subjects
  has_many    :subjects ,:through => :employees_subjects
  has_many    :timetable_entries
  has_many    :employee_bank_details
  has_many    :employee_additional_details
  has_many    :apply_leaves
  has_many    :monthly_payslips
  has_many    :employee_salary_structures
  has_many    :finance_transactions, :as => :payee
  has_many    :cancelled_finance_transactions, :foreign_key => :payee_id,:conditions=>  ['payee_type = ?', 'Employee']
  has_many    :employee_attendances
  has_many    :timetable_swaps
  has_and_belongs_to_many :batches,:join_table => "batch_tutors"
  has_many    :individual_payslip_categories
  accepts_nested_attributes_for :individual_payslip_categories,:allow_destroy=>true
  accepts_nested_attributes_for :monthly_payslips,:allow_destroy=>true
  validates_format_of     :employee_number, :with => /^[A-Z0-9_-]*$/i,
    :message => :must_contain_only_letters

  validates_format_of     :email, :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i,   :allow_blank=>true,
    :message => :must_be_a_valid_email_address

  validates_presence_of :employee_category_id, :employee_number, :first_name, :employee_position_id,
    :employee_department_id,  :date_of_birth,:joining_date,:nationality_id
  validates_uniqueness_of  :employee_number

  validates_associated :user
  after_validation :create_user_and_validate
  before_save :save_biometric_info
  before_save :status_true
#  after_create :create_default_menu_links
  has_attached_file :photo,
    :styles => {:original=> "125x125#"},
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension"

  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']

  validates_attachment_content_type :photo, :content_type =>VALID_IMAGE_TYPES,
    :message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.photo_file_name.blank? }
  validates_attachment_size :photo, :less_than => 512000,\
    :message=>'must be less than 500 KB.',:if=> Proc.new { |p| p.photo_file_name_changed? }

  after_create :setup_employee_leave

  #  def after_initialize
  #    self.biometric_id = biometric_id.present? ? biometric_id : BiometricInformation.find_by_user_id(user_id).try(:biometric_id)
  #  end
  
  def setup_employee_leave
    leave_type = EmployeeLeaveType.all
    leave_type.each do |e|
      EmployeeLeave.create( :employee_id => id, :employee_leave_type_id => e.id, :leave_count => e.max_leave_count)
    end
  end

  def status_true
    unless self.status==1
      self.status=1
    end
  end

  def save_biometric_info
    biometric_info = BiometricInformation.find_or_initialize_by_user_id(user_id)
    biometric_info.update_attributes(:user_id => user_id,:biometric_id => biometric_id) 
    biometric_info.errors.each{|attr,msg| errors.add(attr.to_sym,"#{msg}")}
    unless errors.blank?
      raise ActiveRecord::Rollback
    end
  end

  def validate
    errors.add(:joining_date, :not_less_than_hundred_year)  if self.joining_date.year < Date.today.year - 100 \
      if self.joining_date.present?
    errors.add(:date_of_birth, :not_less_than_hundred_year) if self.date_of_birth.year < Date.today.year - 100 \
      if self.date_of_birth.present?
    errors.add(:joining_date, :not_less_than_date_of_birth) if self.joining_date < self.date_of_birth \
      if self.date_of_birth.present? and self.joining_date.present?
    errors.add(:date_of_birth, :cant_be_a_future_date) if self.date_of_birth >= Date.today \
      if self.date_of_birth.present?
    errors.add(:gender, :error2) unless ['m', 'f'].include? self.gender.downcase \
      if self.gender.present?
    unless employee_additional_details.blank?
      employee_additional_details.each do |employee_additional_detail|
        unless employee_additional_detail.additional_info==''
          errors.add_to_base(employee_additional_detail.errors.full_messages.map{|e| e+". Please add additional details."}.join(', ')) unless employee_additional_detail.valid?
        end
      end
    end
  end

  def create_user_and_validate
    if self.new_record?
      user_record = self.build_user
      user_record.first_name = self.first_name
      user_record.last_name = self.last_name
      user_record.username = self.employee_number.to_s
      user_record.password = self.employee_number.to_s + "123"
      user_record.role = 'Employee'
      user_record.email = self.email.blank? ? "" : self.email.to_s
      check_user_errors(user_record)
    else
      changes_to_be_checked = ['employee_number','first_name','last_name','email']
      check_changes = self.changed & changes_to_be_checked
      #      self.user.role ||= "Employee"
      unless check_changes.blank?
        emp_user = self.user
        emp_user.username = self.employee_number if check_changes.include?('employee_number')
        emp_user.password = self.employee_number.to_s + "123" if check_changes.include?('employee_number')
        emp_user.first_name = self.first_name if check_changes.include?('first_name')
        emp_user.last_name = self.last_name if check_changes.include?('last_name')
        emp_user.email = self.email.to_s if check_changes.include?('email')
        emp_user.save if check_user_errors(self.user)
      end
    end
  end

  def check_user_errors(user)
    unless user.valid?
      user.errors.each{|attr,msg| errors.add(t(attr.to_sym),"#{msg}")}
      puts ActiveRecord::Rollback
    end
    user.errors.blank?
  end

  def employee_batches
    batches_with_employees = Batch.active.reject{|b| b.employee_id.nil?}
    assigned_batches = batches_with_employees.reject{|e| !e.employee_id.split(",").include?(self.id.to_s)}
    return assigned_batches
  end

  def image_file=(input_data)
    return if input_data.blank?
    self.photo_filename     = input_data.original_filename
    self.photo_content_type = input_data.content_type.chomp
    self.photo_data         = input_data.read
  end

  def max_hours_per_day
    self.employee_grade.max_hours_day unless self.employee_grade.blank?
  end

  def max_hours_per_week
    self.employee_grade.max_hours_week unless self.employee_grade.blank?
  end
  alias_method(:max_hours_day, :max_hours_per_day)
  alias_method(:max_hours_week, :max_hours_per_week)
  
  def next_employee
    next_st = self.employee_department.employees.first(:conditions => "id>#{self.id}",:order => "id ASC")
    next_st ||= employee_department.employees.first(:order => "id ASC")
    next_st ||= self.employee_department.employees.first(:order => "id ASC")
  end

  def previous_employee
    prev_st = self.employee_department.employees.first(:conditions => "id<#{self.id}",:order => "id DESC")
    prev_st ||= employee_department.employees.first(:order => "id DESC")
    prev_st ||= self.employee_department.empoyees.first(:order => "id DESC")
  end

  def full_name
    "#{first_name} #{middle_name} #{last_name}"
  end

  def is_payslip_approved(date)
    approve = MonthlyPayslip.find_all_by_salary_date_and_employee_id(date,self.id,:conditions => ["is_approved = true"])
    if approve.empty?
      return false
    else
      return true
    end
  end

#  def create_default_menu_links
#    default_links = MenuLink.find_all_by_user_type("employee")
#    self.user.menu_links = default_links
#  end

  def is_payslip_rejected(date)
    approve = MonthlyPayslip.find_all_by_salary_date_and_employee_id(date,self.id,:conditions => ["is_rejected = true"])
    if approve.empty?
      return false
    else
      return true
    end
  end

  def self.total_employees_salary(employees,start_date,end_date)
    salary = 0
    employees.each do |e|
      salary_dates = e.all_salaries(start_date,end_date)
      salary_dates.each do |s|
        salary += e.employee_salary(s.salary_date.to_date)
      end
    end
    salary
  end

  def employee_salary(salary_date)

    monthly_payslips = MonthlyPayslip.find(:all,
      :order => 'salary_date desc',
      :conditions => ["employee_id ='#{self.id}'and salary_date = '#{salary_date}' and is_approved = 1"])
    individual_payslip_category = IndividualPayslipCategory.find(:all,
      :order => 'salary_date desc',
      :conditions => ["employee_id ='#{self.id}'and salary_date >= '#{salary_date}'"])
    individual_category_non_deductionable = 0
    individual_category_deductionable = 0
    individual_payslip_category.each do |pc|
      unless pc.is_deduction == true
        individual_category_non_deductionable = individual_category_non_deductionable + pc.amount.to_f
      end
    end

    individual_payslip_category.each do |pc|
      unless pc.is_deduction == false
        individual_category_deductionable = individual_category_deductionable + pc.amount.to_f
      end
    end

    non_deductionable_amount = 0
    deductionable_amount = 0
    monthly_payslips.each do |mp|
      category1 = PayrollCategory.find(mp.payroll_category_id)
      unless category1.is_deduction == true
        non_deductionable_amount = non_deductionable_amount + mp.amount.to_f
      end
    end

    monthly_payslips.each do |mp|
      category2 = PayrollCategory.find(mp.payroll_category_id)
      unless category2.is_deduction == false
        deductionable_amount = deductionable_amount + mp.amount.to_f
      end
    end
    net_non_deductionable_amount = individual_category_non_deductionable + non_deductionable_amount
    net_deductionable_amount = individual_category_deductionable + deductionable_amount

    net_amount = net_non_deductionable_amount - net_deductionable_amount
    return net_amount.to_f
  end


  def salary(start_date,end_date)
    MonthlyPayslip.find_by_employee_id(self.id,:order => 'salary_date desc',
      :conditions => ["salary_date >= '#{start_date.to_date}' and salary_date <= '#{end_date.to_date}' and is_approved = 1"]).salary_date

  end

  def archive_employee(status)
    self.update_attributes(:status_description => status)
    employee_attributes = self.attributes
    employee_attributes.delete "id"
    employee_attributes.delete "photo_file_size"
    employee_attributes.delete "photo_file_name"
    employee_attributes.delete "photo_content_type"
    employee_attributes.delete "created_at"
    employee_attributes["former_id"]= self.id
    archived_employee = ArchivedEmployee.new(employee_attributes)
    archived_employee.photo = self.photo
    if archived_employee.save
      #      self.user.delete unless self.user.nil?
      employee_salary_structures = self.employee_salary_structures
      employee_bank_details = self.employee_bank_details
      employee_additional_details = self.employee_additional_details
      employee_salary_structures.each do |g|
        g.archive_employee_salary_structure(archived_employee.id)
      end
      employee_bank_details.each do |g|
        g.archive_employee_bank_detail(archived_employee.id)
      end
      employee_additional_details.each do |g|
        g.archive_employee_additional_detail(archived_employee.id)
      end
      self.user.biometric_information.try(:destroy)
      self.user.soft_delete
      self.destroy
    end
  end
 

  def all_salaries(start_date,end_date)
    MonthlyPayslip.find_all_by_employee_id(self.id,:select =>"distinct salary_date" ,:order => 'salary_date desc',
      :conditions => ["salary_date >= '#{start_date.to_date}' and salary_date <= '#{end_date.to_date}' and is_approved = 1"])
  end

  def self.calculate_salary(monthly_payslip,individual_payslip_category)
    individual_category_non_deductionable = 0
    individual_category_deductionable = 0
    unless individual_payslip_category.blank?
      individual_payslip_category.each do |pc|
        if pc.is_deduction == true
          individual_category_deductionable = individual_category_deductionable + pc.amount.to_f
        else
          individual_category_non_deductionable = individual_category_non_deductionable + pc.amount.to_f
        end
      end
    end
    non_deductionable_amount = 0
    deductionable_amount = 0
    unless monthly_payslip.blank?
      monthly_payslip.each do |mp|
        unless mp.payroll_category.blank?
          if mp.payroll_category.is_deduction == true
            deductionable_amount = deductionable_amount + mp.amount.to_f
          else
            non_deductionable_amount = non_deductionable_amount + mp.amount.to_f
          end
        end
      end
    end
    net_non_deductionable_amount = individual_category_non_deductionable + non_deductionable_amount
    net_deductionable_amount = individual_category_deductionable + deductionable_amount
    net_amount = net_non_deductionable_amount - net_deductionable_amount

    return_hash = {:net_amount=>net_amount,:net_deductionable_amount=>net_deductionable_amount,\
        :net_non_deductionable_amount=>net_non_deductionable_amount }
    return_hash
  end

  def self.find_in_active_or_archived(id)
    employee = Employee.find(:first,:conditions=>"id=#{id}")
    if employee.blank?
      return  ArchivedEmployee.find(:first,:conditions=>"former_id=#{id}")
    else
      return employee
    end
  end

  def has_dependency
    return true if self.monthly_payslips.present? or self.employees_subjects.present? \
      or self.apply_leaves.present? or self.finance_transactions.present? or self.timetable_entries.present? or self.employee_attendances.present? or self.timetable_swaps.present?
    return true if FedenaPlugin.check_dependency(self,"permanant").present?
    return false
  end

  def former_dependency
    FedenaPlugin.check_dependency(self,"former")
  end

  def find_experience_years
    exp_years = self.experience_year
    date = Date.today
    total_current_exp_days = (date-self.joining_date).to_i
    current_years = (total_current_exp_days/365)
    unless (self.joining_date > date)
      return exp_years.nil? ? current_years : exp_years+current_years
    else
      return exp_years.nil? ? 0 : exp_years
    end
  end

  def find_experience_months
    exp_months = self.experience_month
    date = Date.today
    total_current_exp_days = (date-self.joining_date).to_i
    rem = total_current_exp_days%365
    current_months = rem / 30
    unless (self.joining_date > date)
      return exp_months.nil? ? current_months : exp_months+current_months
    else
      return exp_months.nil? ? 0 : exp_months
    end
  end

  def get_profile_data
    employee = self
    biometric_id = BiometricInformation.find_by_user_id(user_id).try(:biometric_id)
    salary_details = employee_salary_structures
    additional_data = Hash.new
    bank_data = Hash.new
    additional_fields = AdditionalField.all(:conditions=>"status = true")
    additional_fields.each do |additional_field|
      detail = EmployeeAdditionalDetail.find_by_additional_field_id_and_employee_id(additional_field.id,employee.id)
      additional_data[additional_field.name] = detail.try(:additional_info)
    end
    bank_fields = BankField.all(:conditions=>"status = true")
    bank_fields.each do |bank_field|
      detail = EmployeeBankDetail.find_by_bank_field_id_and_employee_id(bank_field.id,employee.id)
      bank_data[bank_field.name] = detail.try(:bank_info)
    end
    exp_years = employee.experience_year
    exp_months = employee.experience_month
    date = Date.today
    total_current_exp_days = (date-employee.joining_date).to_i
    current_years = (total_current_exp_days/365)
    rem = total_current_exp_days%365
    current_months = rem/30
    total_month = (exp_months || 0)+current_months
    year = total_month/12
    month = total_month%12
    total_years = (exp_years || 0)+current_years+year
    total_months = month
    [employee,additional_data,bank_data,total_years,total_months,salary_details,biometric_id]
  end

  def self.employee_details(parameters)
    sort_order=parameters[:sort_order]
    if sort_order.nil?
      employees=Employee.all(:select=>"employees.first_name,employees.middle_name,employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `employees`.reporting_manager_id",:order=>'first_name ASC')
    else
      employees=Employee.all(:select=>"employees.first_name,employees.middle_name,employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `employees`.reporting_manager_id",:order=>sort_order)
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('employee_id') }","#{t('joining_date') }","#{t('department')}","#{t('position')}","#{t('manager')}","#{t('gender')}"]
    data << col_heads
    employees.each_with_index do |e,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{e.full_name}"
      col<< "#{e.employee_number}"
      col<< "#{e.joining_date}"
      col<< "#{e.department_name}"
      col<< "#{e.emp_position}"
      col<< "#{e.manager_first_name} #{e.manager_last_name}"
      col<< "#{e.gender.downcase=='m' ? t('m') : t('f')}"
      col=col.flatten
      data<< col
    end
    return data
  end

  def self.employee_subject_association(parameters)
    sort_order=parameters[:sort_order]
    if sort_order.nil?
      employees= Employee.all(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employees_subjects.id) as emp_sub_count,employee_number",:joins=>[:employees_subjects,:employee_department],:group=>"employees.id",:order=>'first_name ASC',:include=>{:subjects=>[:employees_subjects,{:batch=>:course}]})
    else
      employees= Employee.all(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employees_subjects.id) as emp_sub_count,employee_number",:joins=>[:employees_subjects,:employee_department],:group=>"employees.id",:order=>sort_order,:include=>{:subjects=>[:employees_subjects,{:batch=>:course}]})
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('employee_id') }","#{t('department')}","#{t('subject')}(#{t('batch_name')})"]
    data << col_heads
    employees.each_with_index do |obj,i|
      col=[]
      col << "#{i+1}"
      col << "#{obj.full_name}"
      col << "#{obj.employee_number}"
      col << "#{obj.department_name}"
      col << "#{obj.subjects.map{|s| "#{s.name} ( #{s.batch.course.code} #{s.batch.name} )"}.join("\n" )}"
      col=col.flatten
      data << col
    end
    return data
  end

  def self.employee_payroll_details(parameters)
    sort_order=parameters[:sort_order]
    department_id=parameters[:department_id]
    if department_id.nil? or department_id.blank?
      if sort_order.nil?
        employees= Employee.all(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employee_salary_structures.id) as emp_sub_count,employee_number",:joins=>[:employee_salary_structures,:employee_department],:group=>"employees.id" ,:order=>'first_name ASC')
        emp_ids=employees.collect(&:id)
        payroll=EmployeeSalaryStructure.all(:select=>"employee_id,amount,payroll_categories.name,payroll_categories.is_deduction",:joins=>[:payroll_category],:conditions=>["payroll_categories.status=? and employee_id IN (?)",true,emp_ids],:order=>'name ASC').group_by(&:employee_id)
      else
        employees= Employee.all(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employee_salary_structures.id) as emp_sub_count,employee_number",:joins=>[:employee_salary_structures,:employee_department],:group=>"employees.id",:order=>sort_order)
        emp_ids=employees.collect(&:id)
        payroll=EmployeeSalaryStructure.all(:select=>"employee_id,amount,payroll_categories.name,payroll_categories.is_deduction",:joins=>[:payroll_category],:conditions=>["payroll_categories.status=? and employee_id IN (?)",true,emp_ids],:order=>'name ASC').group_by(&:employee_id)
      end
    else
      if sort_order.nil?
        employees= Employee.all(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employee_salary_structures.id) as emp_sub_count,employee_number",:joins=>[:employee_salary_structures,:employee_department],:group=>"employees.id",:conditions=>["employee_departments.id=?",department_id] ,:order=>'first_name ASC')
        emp_ids=employees.collect(&:id)
        payroll=EmployeeSalaryStructure.all(:select=>"employee_id,amount,payroll_categories.name,payroll_categories.is_deduction",:joins=>[:payroll_category],:conditions=>["payroll_categories.status=? and employee_id IN (?)",true,emp_ids],:order=>'name ASC').group_by(&:employee_id)
      else
        employees= Employee.all(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employee_salary_structures.id) as emp_sub_count,employee_number",:joins=>[:employee_salary_structures,:employee_department],:group=>"employees.id",:conditions=>["employee_departments.id=?",department_id],:order=>sort_order)
        emp_ids=employees.collect(&:id)
        payroll=EmployeeSalaryStructure.all(:select=>"employee_id,amount,payroll_categories.name,payroll_categories.is_deduction",:joins=>[:payroll_category],:conditions=>["payroll_categories.status=? and employee_id IN (?)",true,emp_ids],:order=>'name ASC').group_by(&:employee_id)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('employee_id') }","#{t('department')}","#{t('payroll_text')} #{t('details')}(#{Configuration.currency})"]
    data << col_heads
    employees.each_with_index do |e,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{e.full_name}"
      col<< "#{e.employee_number}"
      col<< "#{e.department_name}"
      pay_roll=payroll[e.id]
      unless pay_roll.nil?
        pay=[]
        total=0.to_f
        pay_roll.each do |p|
          pay << "#{p.name} - #{p.amount.blank? ? 0.00 :p.amount}"
          if p.is_deduction=="1"
            total-=p.amount.to_f
          else
            total+=p.amount.to_f
          end
        end
        pay << "#{t('total')} - #{total}"
        col << "#{pay.join("\n")}"
      else
        col<< "-"
      end
      col=col.flatten
      data<< col
    end
    return data
  end

end
