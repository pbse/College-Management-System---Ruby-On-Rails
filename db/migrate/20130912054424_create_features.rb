class CreateFeatures < ActiveRecord::Migration
  def self.up
    create_table :features do |t|
      t.string  :feature_key
      t.boolean :is_enabled ,:default=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :features
  end
end
