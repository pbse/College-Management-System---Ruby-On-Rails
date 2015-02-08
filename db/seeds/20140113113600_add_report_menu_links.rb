cat = MenuLinkCategory.find_by_name("data_and_reports")
unless cat.nil?
  cat.allowed_roles << :reports_view unless cat.allowed_roles.include?(:reports_view)
  cat.save

  higher_link=MenuLink.find_or_create_by_name_and_higher_link_id(:name=>'reports_text',:target_controller=>'report',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'report-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id)



  MenuLink.create(:name=>'course_batch_details',:target_controller=>'report',:target_action=>'course_batch_details',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'course_batch_details')
  MenuLink.create(:name=>'former_student_details',:target_controller=>'report',:target_action=>'former_students',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'former_student_details')
  MenuLink.create(:name=>'former_employee_details',:target_controller=>'report',:target_action=>'former_employees',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'former_employee_details')
  MenuLink.create(:name=>'subject_details',:target_controller=>'report',:target_action=>'subject_details',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'subject_details')
  MenuLink.create(:name=>'employee_subject_association_details',:target_controller=>'report',:target_action=>'employee_subject_association',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'employee_subject_association_details')
  MenuLink.create(:name=>'employee_payroll_details',:target_controller=>'report',:target_action=>'employee_payroll_details',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'employee_payroll_details')
  MenuLink.create(:name=>'exam_schedule_details',:target_controller=>'report',:target_action=>'exam_schedule_details',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'exam_schedule_details')
  MenuLink.create(:name=>'fee_collection_details',:target_controller=>'report',:target_action=>'fee_collection_details',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'fee_collection_details')
  MenuLink.create(:name=>'course_fee_defaulters',:target_controller=>'report',:target_action=>'course_fee_defaulters',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'course_fee_defaulters')
  MenuLink.create(:name=>'student_wise_fee_defaulters',:target_controller=>'report',:target_action=>'student_wise_fee_defaulters',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'student_wise_fee_defaulters')
end
