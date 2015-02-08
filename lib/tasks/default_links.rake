task :update_default_links => :environment do
  all_users = User.all
  all_users.each do|user|
    if user.menu_links.count == 0
      default_links = []
      if user.admin?
        main_links = MenuLink.find_all_by_name(["human_resource","settings","students","calendar_text","news_text","event_creations"])
        default_links = default_links + main_links
        main_links.each do|link|
          sub_links = MenuLink.find_all_by_higher_link_id(link.id)
          default_links = default_links + sub_links
        end
      elsif user.employee?
        own_links = MenuLink.find_all_by_user_type("employee")
        default_links = own_links + MenuLink.find_all_by_name(["news_text","calendar_text"])
      else
        own_links = MenuLink.find_all_by_name_and_user_type(["my_profile","timetable_text","academics"],"student")
        default_links = own_links + MenuLink.find_all_by_name(["news_text","calendar_text"])
      end
      user.menu_links = default_links
    end
  end
end