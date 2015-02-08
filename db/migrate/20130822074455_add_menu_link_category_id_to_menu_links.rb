class AddMenuLinkCategoryIdToMenuLinks < ActiveRecord::Migration
  def self.up
    add_column :menu_links, :menu_link_category_id, :integer
  end

  def self.down
    remove_column :menu_links, :menu_link_category_id
  end
end
