class BatchTutorJoinTable < ActiveRecord::Migration
  def self.up
    create_table :batch_tutors, :id => false do |t|
      t.references :employee
      t.references :batch
    end
    add_index :batch_tutors, [:employee_id, :batch_id]
  end

  def self.down
    drop_table :batch_tutors
  end
end
