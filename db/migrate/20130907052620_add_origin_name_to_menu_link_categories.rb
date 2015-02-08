class AddOriginNameToMenuLinkCategories < ActiveRecord::Migration
  def self.up
    add_column :menu_link_categories, :origin_name, :string
  end

  def self.down
    remove_column :menu_link_categories, :origin_name
  end
end
