class AddLinkTypeToMenuLinks < ActiveRecord::Migration
  def self.up
	add_column :menu_links,:link_type,:string
	add_column :menu_links,:user_type,:string
  end

  def self.down
	remove_column :menu_links,:link_type
	remove_column :menu_links,:user_type
  end
end
