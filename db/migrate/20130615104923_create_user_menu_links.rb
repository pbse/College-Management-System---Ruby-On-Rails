class CreateUserMenuLinks < ActiveRecord::Migration
  def self.up
    create_table :user_menu_links do |t|
      t.references :user
      t.references :menu_link

      t.timestamps
    end
  end

  def self.down
    drop_table :user_menu_links
  end
end
