class ChangeDescriptionFormatInEvents < ActiveRecord::Migration
  def self.up
    change_column :events, :description, :text
  end

  def self.down
    change_column :events, :description, :string
  end
end
