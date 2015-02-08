class AddIconClassToMenuLinks < ActiveRecord::Migration
  def self.up
    add_column :menu_links, :icon_class, :string
  end

  def self.down
    remove_column :menu_links, :icon_class
  end
end
