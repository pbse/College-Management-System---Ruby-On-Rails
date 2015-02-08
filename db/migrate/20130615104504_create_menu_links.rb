class CreateMenuLinks < ActiveRecord::Migration
  def self.up
    create_table :menu_links do |t|
      t.string :name
      t.string :target_controller
      t.string :target_action
      t.integer :higher_link_id

      t.timestamps
    end
  end

  def self.down
    drop_table :menu_links
  end
end
