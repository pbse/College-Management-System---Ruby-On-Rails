class ChangeGradePointType < ActiveRecord::Migration
  def self.up
    change_column :assessment_scores,  :grade_points, :float
  end

  def self.down
  end
end
