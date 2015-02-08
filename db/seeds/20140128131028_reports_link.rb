cat = MenuLinkCategory.find_by_name("administration")
unless cat.nil?
 
  higher_link=MenuLink.find_or_create_by_name_and_higher_link_id(:name=>'finance_text',:higher_link_id=>nil)

  MenuLink.create(:name=>'finance_reports',:target_controller=>'finance',:target_action=>'finance_reports',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'finance_reports')
 
end
