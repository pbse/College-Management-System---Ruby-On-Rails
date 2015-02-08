class ChangeCceScoreValue < ActiveRecord::Migration
  def self.convert
    AssessmentScore.scholastic.all(:include=>[{:descriptive_indicator=>{:describable=>:fa_group}},{:exam=>{:exam_group=>:batch}}]).each do |score|
      grade = score.exam.exam_group.batch.grading_level_list.to_a.find{|f| f.credit_points.to_i == score.grade_points}
      max_mark = score.descriptive_indicator.describable.fa_group.try(:max_marks) ? score.descriptive_indicator.describable.fa_group.try(:max_marks) : 0
      score.grade_points = (grade ? grade.min_score : 0) * max_mark / 100
      score.save
    end
  end
  def self.up
    if(MultiSchool rescue nil)
      School.active.each do |school|
        MultiSchool.current_school = school
        convert
      end if ActiveRecord::Base.connection.tables.include?('schools')
    else
      convert
    end
  end

  def self.down
    
  end
end
