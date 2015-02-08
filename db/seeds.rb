[
  {"config_key" => "InstitutionName"                 ,"config_value" => "" },
  {"config_key" => "InstitutionAddress"              ,"config_value" => ""},
  {"config_key" => "InstitutionPhoneNo"              ,"config_value" => ""},
  {"config_key" => "StudentAttendanceType"           ,"config_value" => "Daily"},
  {"config_key" => "CurrencyType"                    ,"config_value" => "$"},
  {"config_key" => "Locale"                          ,"config_value" => "en"},
  {"config_key" => "AdmissionNumberAutoIncrement"    ,"config_value" => "1"},
  {"config_key" => "EmployeeNumberAutoIncrement"     ,"config_value" => "1"},
  {"config_key" => "TotalSmsCount"                   ,"config_value" => "0"},
  {"config_key" => "FinancialYearStartDate"          ,"config_value" => Date.today},
  {"config_key" => "FinancialYearEndDate"            ,"config_value" => Date.today+1.year},
  {"config_key" => "AutomaticLeaveReset"             ,"config_value" => "0"},
  {"config_key" => "LeaveResetPeriod"                ,"config_value" => "4"},
  {"config_key" => "LastAutoLeaveReset"              ,"config_value" => nil},
  {"config_key" => "GPA"                             ,"config_value" => "0"},
  {"config_key" => "CWA"                             ,"config_value" => "0"},
  {"config_key" => "CCE"                             ,"config_value" => "0"},
  {"config_key" => "DefaultCountry"                  ,"config_value" => Country.find_by_name('India')? "#{Country.find_by_name('India').id}" : "76"},
  {"config_key" => "FirstTimeLoginEnable"            ,"config_value" => "0"},
  {"config_key" => "FeeReceiptNo"                    ,"config_value" => nil},
  {"config_key" => "PrecisionCount"                  ,"config_value" => "2"}
].each do |param|
  Configuration.find_or_create_by_config_key(param)
end

[
  {"config_key" => "AvailableModules"                ,"config_value" => "HR"},
  {"config_key" => "AvailableModules"                ,"config_value" => "Finance"}
].each do |param|
  Configuration.find_or_create_by_config_key_and_config_value(param)
end

if GradingLevel.count == 0
  [
    {"name" => "A"   ,"min_score" => 90 },
    {"name" => "B"   ,"min_score" => 80},
    {"name" => "C"   ,"min_score" => 70},
    {"name" => "D"   ,"min_score" => 60},
    {"name" => "E"   ,"min_score" => 50},
    {"name" => "F"   ,"min_score" => 0}
  ].each do |param|
    GradingLevel.create(param)
  end
end


if User.first( :conditions=>{:admin=>true}).blank?

  employee_category = EmployeeCategory.find_or_create_by_prefix(:name => 'System Admin',:prefix => 'Admin',:status => true)

  employee_position = EmployeePosition.find_or_create_by_name(:name => 'System Admin',:employee_category_id => employee_category.id,:status => true)

  employee_department = EmployeeDepartment.find_or_create_by_code(:code => 'Admin',:name => 'System Admin',:status => true)

  employee_grade = EmployeeGrade.find_or_create_by_name(:name => 'System Admin',:priority => 0 ,:status => true,:max_hours_day=>nil,:max_hours_week=>nil)

  employee = Employee.find_or_create_by_employee_number(:employee_number => 'admin',:joining_date => Date.today,:first_name => 'Admin',:last_name => 'User',
    :employee_department_id => employee_department.id,:employee_grade_id => employee_grade.id,:employee_position_id => employee_position.id,:employee_category_id => employee_category.id,:status => true,:nationality_id =>'76', :date_of_birth => Date.today-365, :email => 'noreply@fedena.com',:gender=> 'm')

  employee.user.update_attributes(:admin=>true,:employee=>false)

end

[
  {"name" => 'Salary'         ,"description" => ' ',"is_income" => false },
  {"name" => 'Donation'       ,"description" => ' ',"is_income" => true},
  {"name" => 'Fee'            ,"description" => ' ',"is_income" => true},
  {"name" => 'Refund'         ,"description" => ' ',"is_income" => false}
].each do |param|
  FinanceTransactionCategory.find_or_create_by_name(param)
end

[
  {"settings_key" => "ApplicationEnabled"                 ,"is_enabled" => false },
  {"settings_key" => "ParentSmsEnabled"                   ,"is_enabled" => false},
  {"settings_key" => "EmployeeSmsEnabled"                 ,"is_enabled" => false},
  {"settings_key" => "StudentSmsEnabled"                  ,"is_enabled" => false},
  {"settings_key" => "ResultPublishEnabled"               ,"is_enabled" => false},
  {"settings_key" => "StudentAdmissionEnabled"            ,"is_enabled" => false},
  {"settings_key" => "ExamScheduleResultEnabled"          ,"is_enabled" => false},
  {"settings_key" => "AttendanceEnabled"                  ,"is_enabled" => false},
  {"settings_key" => "NewsEventsEnabled"                  ,"is_enabled" => false}
].each do |param|
  SmsSetting.find_or_create_by_settings_key(param)
end


Privilege.all.each do |p|
  p.update_attributes(:description=> p.name.underscore+"_privilege")
end

Event.all.each do |e|
  e.destroy if e.origin_type=="AdditionalExam"
end

#insert record in privilege_tags table
[
  {"name_tag" => "system_settings", "priority"=>5},
  {"name_tag" => "administration_operations", "priority"=>1},
  {"name_tag" => "academics", "priority"=>3},
  {"name_tag" => "student_management", "priority"=>2},
  {"name_tag" => "social_other_activity", "priority"=>4},
].each do |param|
  PrivilegeTag.find_or_create_by_name_tag(param)
end

#add priorities to student additional fields with nil priority, if any
addl_fields = StudentAdditionalField.all
unless addl_fields.empty?
  priority=1
  last_priority = addl_fields.collect(&:priority).compact.sort.last
  unless last_priority.nil?
    priority = last_priority + 1
  end
  nil_priority_fields = addl_fields.reject{|f| !(f.priority.nil?)}
  nil_priority_fields.each do|p|
    p.update_attributes(:priority=>priority)
    priority+=1
  end
end

#add priorities to employee additional fields with nil priority, if any
addl_fields = AdditionalField.all
unless addl_fields.empty?
  priority=1
  last_priority = addl_fields.collect(&:priority).compact.sort.last
  unless last_priority.nil?
    priority = last_priority + 1
  end
  nil_priority_fields = addl_fields.reject{|f| !(f.priority.nil?)}
  nil_priority_fields.each do|p|
    p.update_attributes(:priority=>priority)
    priority+=1
  end
end


#add privilege_tag_id, priority in privileges table
#system_settings
Privilege.reset_column_information
system_settings_tag = PrivilegeTag.find_by_name_tag('system_settings')
Privilege.find_by_name('GeneralSettings').update_attributes(:privilege_tag_id=>system_settings_tag.id, :priority=>10 )
Privilege.find_by_name('AddNewBatch').update_attributes(:privilege_tag_id=>system_settings_tag.id, :priority=>20 )
Privilege.find_by_name('SubjectMaster').update_attributes(:privilege_tag_id=>system_settings_tag.id, :priority=>30 )
Privilege.find_by_name('SMSManagement').update_attributes(:privilege_tag_id=>system_settings_tag.id, :priority=>40 )


#administration_operations
administration_operations_tag = PrivilegeTag.find_by_name_tag('administration_operations')
Privilege.find_by_name('HrBasics').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>50 )
Privilege.find_by_name('EmployeeSearch').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>60 )
Privilege.find_by_name('EmployeeAttendance').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>70 )
Privilege.find_by_name('PayslipPowers').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>80 )
Privilege.find_by_name('FinanceControl').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>90 )
Privilege.find_by_name('EventManagement').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>100 )
Privilege.find_by_name('ManageNews').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>110 )
#academics
academics_tag = PrivilegeTag.find_by_name_tag('academics')
Privilege.find_by_name('ExaminationControl').update_attributes(:privilege_tag_id=>academics_tag.id, :priority=>230 )
Privilege.find_by_name('EnterResults').update_attributes(:privilege_tag_id=>academics_tag.id, :priority=>240 )
Privilege.find_by_name('ViewResults').update_attributes(:privilege_tag_id=>academics_tag.id, :priority=>250 )
Privilege.find_by_name('ManageTimetable').update_attributes(:privilege_tag_id=>academics_tag.id, :priority=>260 )
Privilege.find_by_name('TimetableView').update_attributes(:privilege_tag_id=>academics_tag.id, :priority=>270 )
#student_management
student_management_tag = PrivilegeTag.find_by_name_tag('student_management')
Privilege.find_by_name('Admission').update_attributes(:privilege_tag_id=>student_management_tag.id, :priority=>280 )
Privilege.find_by_name('StudentsControl').update_attributes(:privilege_tag_id=>student_management_tag.id, :priority=>290 )
Privilege.find_by_name('StudentView').update_attributes(:privilege_tag_id=>student_management_tag.id, :priority=>300 )
Privilege.find_by_name('StudentAttendanceRegister').update_attributes(:privilege_tag_id=>student_management_tag.id, :priority=>310 )
Privilege.find_by_name('StudentAttendanceView').update_attributes(:privilege_tag_id=>student_management_tag.id, :priority=>320 )

#update gender as string
Employee.all.each do |e|
  if e.gender.to_s=="1"
    e.update_attributes(:gender=> "m")
  elsif e.gender.to_s=="0"
    e.update_attributes(:gender=> "f")
  end
end

ArchivedEmployee.all.each do |e|
  if e.gender.to_s=="1"
    e.update_attributes(:gender=> "m")
  elsif e.gender.to_s=="0"
    e.update_attributes(:gender=> "f")
  end
end


if Country.find_by_name("Venezuea").present?
  Country.find_by_name("Venezuea").update_attribute(:name, "Venezuela")  #Spell Correct for Venezuela
end

#multiple Venezuela entries delete
countries= Country.find_all_by_name("Venezuela")
if countries.count>1
  country_ids = countries.collect(&:id)
  venezuela_id=country_ids.first
  deleted_country_ids= country_ids.dup - [venezuela_id]

  Student.update_all("nationality_id = #{venezuela_id}", ["nationality_id in (?)",deleted_country_ids])
  Student.update_all("country_id = #{venezuela_id}", ["country_id in (?)",deleted_country_ids])
  ArchivedStudent.update_all("nationality_id = #{venezuela_id}", ["nationality_id in (?)",deleted_country_ids])
  ArchivedStudent.update_all("country_id = #{venezuela_id}", ["country_id in (?)",deleted_country_ids])

  Guardian.update_all("country_id = #{venezuela_id}", ["country_id in (?)",deleted_country_ids])
  ArchivedGuardian.update_all("country_id = #{venezuela_id}", ["country_id in (?)",deleted_country_ids])

  Employee.update_all("nationality_id = #{venezuela_id}", ["nationality_id in (?)",deleted_country_ids])
  Employee.update_all("home_country_id = #{venezuela_id}", ["home_country_id in (?)",deleted_country_ids])
  Employee.update_all("office_country_id = #{venezuela_id}", ["office_country_id in (?)",deleted_country_ids])
  ArchivedEmployee.update_all("nationality_id = #{venezuela_id}", ["nationality_id in (?)",deleted_country_ids])
  ArchivedEmployee.update_all("home_country_id = #{venezuela_id}", ["home_country_id in (?)",deleted_country_ids])
  ArchivedEmployee.update_all("office_country_id = #{venezuela_id}", ["office_country_id in (?)",deleted_country_ids])

  default_country=Configuration.find_by_config_key("DefaultCountry")
  if default_country.present?
    if deleted_country_ids.include?(default_country.config_value.to_i)
      default_country.update_attributes(:config_value=>venezuela_id)
    end
  end

  deleted_country_ids.each do |dc|
    country = Country.find_by_id(dc)
    country.destroy if country.present?
  end
end

unless Configuration.find_by_config_key("SetupAttendance").try(:config_value) == "1"
  SetupAttendance.setup_weekdays
  SetupAttendance.setup_class_timings
  SetupAttendance.setup_timetable
  Configuration.create(:config_key => "SetupAttendance",:config_value => "1")
end

unless Configuration.find_by_config_key("SetupSibling").try(:config_value) == "1"
 
  Student.find_in_batches(:batch_size=>200){|sts| sts.each{|s| Student.connection.execute("UPDATE `students` SET `sibling_id` = '#{s.id}' WHERE `id` = #{s.id};") }}
  ArchivedStudent.find_in_batches(:batch_size=>200){|sts| sts.each{|s| ArchivedStudent.connection.execute("UPDATE `archived_students` SET `sibling_id` = '#{s.id}' WHERE `id` = #{s.id};") }}
  Configuration.create(:config_key => "SetupSibling",:config_value => "1")
end

unless Configuration.find_by_config_key("SetupBalanceFee").try(:config_value) == "1"
  # FinanceFee.find_in_batches(:batch_size=>200,:conditions=>{:is_paid=>false}){|batch| batch.each{|fee| fee.update_attributes(:balance=>fee.finance_fee_collection.student_fee_balance(fee.student)) if fee.student.present?}}
  FinanceFee.find_in_batches(:batch_size=>500,:conditions=>["is_paid=false and fee_collection_particulars.is_deleted=0"],:joins=>'INNER JOIN finance_fee_collections on finance_fee_collections.id=fee_collection_id INNER JOIN students on students.id=student_id LEFT OUTER JOIN fee_collection_particulars on fee_collection_particulars.finance_fee_collection_id=finance_fees.fee_collection_id ',:select=>'sum(fee_collection_particulars.amount) as amt,finance_fees.*',:group=>'fee_collection_id,finance_fees.student_id') do |fees|
    fees.each do |fee|
      paid_fees = FinanceTransaction.find(:all,:conditions=>"FIND_IN_SET(id,\"#{fee.transaction_id}\")") unless fee.transaction_id.blank?
      collection=fee.finance_fee_collection
      student=fee.student
      batch_discounts = BatchFeeCollectionDiscount.find_all_by_finance_fee_collection_id(collection.id)
      student_discounts = StudentFeeCollectionDiscount.find_all_by_finance_fee_collection_id_and_receiver_id(collection.id,student.id)
      category_discounts = StudentCategoryFeeCollectionDiscount.find_all_by_finance_fee_collection_id_and_receiver_id(collection.id,student.student_category_id)
      total_discount1 = 0
      total_discount=[]
      total_discount << batch_discounts.map{|s| fee.amt.to_f * s.discount(student) / 100}.sum.to_f unless batch_discounts.nil?
      total_discount << student_discounts.map{|s| fee.amt.to_f * s.discount(student) / 100}.sum.to_f unless student_discounts.nil?
      total_discount << category_discounts.map{|s| fee.amt.to_f * s.discount(student) / 100}.sum.to_f unless category_discounts.nil?
      total_discount1=total_discount.reject{|s1| s1.nan?}.sum
      total_fees = fee.amt.to_i
      total_fees -= total_discount1
      unless paid_fees.nil?
        paid = 0
        fine = 0
        paid += paid_fees.collect{|x|x.amount.to_f}.sum
        total_fees -= paid
        fine += paid_fees.collect{|f|f.fine_amount.to_f}.sum
        total_fees += fine
      end
      
      
      FinanceFee.connection.execute("UPDATE `finance_fees` SET `balance` = '#{total_fees}' WHERE `id` = #{fee.id};")
      #fee.update_attributes(:balance=>total_fees)
    end
   
  end
  Configuration.create(:config_key => "SetupBalanceFee",:config_value => "1")
end

 

#new timezone add
[
  {"name" => "Baker Island Time","code" => "BIT", "difference_type" => "-", "time_difference" => "43200"},
  {"name" => "Marquesas Islands Time","code" => "MART", "difference_type" => "-", "time_difference" => "34200"},
  {"name" => "Venezuelan Standard Time","code" => "VET", "difference_type" => "-", "time_difference" => "16200"},
  {"name" => "Brasilia Time","code" => "BRT", "difference_type" => "-", "time_difference" => "7200"},
  {"name" => "Afghanistan Time","code" => "AFT", "difference_type" => "+", "time_difference" => "16200"},
  {"name" => "Nepal Time","code" => "NPT", "difference_type" => "+", "time_difference" => "20700"},
  {"name" => "Myanmar Time","code" => "MMT", "difference_type" => "+", "time_difference" => "23400"},
  {"name" => "Central Western Standard Time","code" => "CWST", "difference_type" => "+", "time_difference" => "31500"},
  {"name" => "Australian Central Daylight Time","code" => "ACDT", "difference_type" => "+", "time_difference" => "37800"},
  {"name" => "Norfolk Time","code" => "NFT", "difference_type" => "+", "time_difference" => "41400"},
  {"name" => "Chatham Standard Time","code" => "CHAST", "difference_type" => "+", "time_difference" => "45900"},
  {"name" => "Samoa Standard Time","code" => "SST", "difference_type" => "+", "time_difference" => "46800"},
  {"name" => "Line Islands Time","code" => "LINT", "difference_type" => "+", "time_difference" => "50400"},
  {"name" => "Venezuelan Standard Time","code" => "VET", "difference_type" => "-", "time_difference" => "16200"}
].each do |param|
  TimeZone.find_or_create_by_name(param)
end

unless Configuration.find_by_config_key("SetupTutors").try(:config_value) == "1"
  batches=Batch.find(:all,:conditions=>['employee_id!=?',''])
  batches.each do |batch|
    employee_ids=batch.employee_id.split(",")
    employee_ids.each do |e|
      unless Employee.find_by_id(e.to_i).nil?
        batch.employee_ids = batch.employee_ids << e.to_i
      end
    end
  end
  Configuration.create(:config_key => "SetupTutors",:config_value => "1")
end

unless Configuration.find_by_config_key('SetupLeavetype').try(:config_value) == "1"
  employee_leave_type = EmployeeLeaveType.all
  employees = Employee.all
  employees.each do |employee|
    employee_leaves = EmployeeLeave.all(:conditions => {:employee_id => employee.id})
    leaves_to_create = employee_leave_type.map(&:id) - employee_leaves.map(&:employee_leave_type_id).uniq
    employee_leaves.each do |existing_leave|
      leave_type = existing_leave.employee_leave_type
      attendances = EmployeeAttendance.find_all_by_employee_leave_type_id_and_employee_id(leave_type.id,employee.id)
      taken_leave = 0
      attendances.each do |attendance|
        taken_leave += 1 if attendance.is_half_day == false
        taken_leave += 0.5 if attendance.is_half_day == true
      end
      existing_leave.update_attributes(:leave_taken => taken_leave,:leave_count => leave_type.max_leave_count.to_f)
    end
    leaves_to_create.each do |create|
      leave_type = EmployeeLeaveType.find_by_id(create)
      attendances = EmployeeAttendance.find_all_by_employee_leave_type_id_and_employee_id(create,employee.id)
      taken_leave = 0
      attendances.each do |attendance|
        taken_leave += 1 if attendance.is_half_day == false
        taken_leave += 0.5 if attendance.is_half_day == true
      end
      EmployeeLeave.create( :employee_id => employee.id, :employee_leave_type_id => create, :leave_taken => taken_leave,:leave_count => leave_type.max_leave_count.to_f)
    end
  end
  Configuration.create(:config_key => "SetupLeavetype",:config_value => "1")
end
#  AdditionalFieldOption
AdditionalFieldOption.reset_column_information
AdditionalField.reset_column_information
if AdditionalFieldOption.column_names.include?("school_id") and AdditionalField.column_names.include?("school_id")
  unless ActiveRecord::Base.connection.execute("select count(*) from additional_field_options where school_id is NULL").all_hashes.first["count(*)"]=="0"
    sql_update = "update additional_field_options INNER JOIN additional_fields ON (additional_fields.id = additional_field_options.additional_field_id) set additional_field_options.school_id=additional_fields.school_id"
    ActiveRecord::Base.connection.execute(sql_update)
  end
end

#  BatchStudent
BatchStudent.reset_column_information
Batch.reset_column_information
if BatchStudent.column_names.include?("school_id") and Batch.column_names.include?("school_id")
  unless ActiveRecord::Base.connection.execute("select count(*) from batch_students where school_id is NULL").all_hashes.first["count(*)"]=="0"
    sql_update = "update batch_students INNER JOIN batches ON (batches.id = batch_students.batch_id) set batch_students.school_id=batches.school_id"
    ActiveRecord::Base.connection.execute(sql_update)
  end
end
unless Configuration.find_by_config_key("AdditionalReportsPrivilege").try(:config_value) == "1"
  Privilege.reset_column_information
  Privilege.create :name => 'ReportsView' , :description => 'additional_reports_view'
  if Privilege.column_names.include?("privilege_tag_id")
    Privilege.find_by_name('ReportsView').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('academics').id, :priority=> 321 )
  end
  Configuration.create(:config_key => "AdditionalReportsPrivilege",:config_value => "1")
end
