class MenuLinkCategory < ActiveRecord::Base

  has_many :menu_links

  serialize :allowed_roles

end
