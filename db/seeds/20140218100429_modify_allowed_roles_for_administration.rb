cat = MenuLinkCategory.find_by_name("administration")
unless cat.nil?
  a = cat.allowed_roles
  a.push([:add_new_batch,:sms_management,:subject_master])
  a.flatten!
  cat.allowed_roles = a.uniq
  cat.save

end