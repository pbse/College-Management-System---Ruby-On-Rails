class CorePaperclipPathUpdate < ActiveRecord::Migration
  def self.up
    Rake::Task["fedena:data:update_paths"].execute
  end

  def self.down
  end
end
