class AddSchoolIdToRedactorUpload < ActiveRecord::Migration
  def self.up
    add_column :redactor_uploads,:school_id,:integer
  end

  def self.down
    remove_column :redactor_uploads,:school_id
  end
end
