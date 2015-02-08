class MenuLink < ActiveRecord::Base

  has_many :user_menu_links
  belongs_to :user
  belongs_to :menu_link_category
  belongs_to :higher_link, :class_name=>"MenuLink", :foreign_key=>"higher_link_id"
  has_many :lower_links, :class_name=>"MenuLink", :foreign_key=>"higher_link_id"

end
