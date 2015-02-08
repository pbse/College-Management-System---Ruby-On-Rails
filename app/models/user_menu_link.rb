class UserMenuLink < ActiveRecord::Base
  belongs_to :user
  belongs_to :menu_link

  #validates_presence_of :user_id,:menu_link_id
end
