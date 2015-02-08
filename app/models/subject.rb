#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class Subject < ActiveRecord::Base

  belongs_to :batch
  belongs_to :elective_group
  has_many :timetable_entries,:foreign_key=>'subject_id'
  has_many :employees_subjects
  has_many :employees ,:through => :employees_subjects
  has_many :students_subjects
  has_many :students, :through => :students_subjects
  has_many :grouped_exam_reports
  has_many :timetable_swaps
  has_many :subject_leaves
  has_and_belongs_to_many_with_deferred_save :fa_groups
  validates_presence_of :name, :max_weekly_classes, :code,:batch_id
  validates_presence_of :credit_hours, :if=>:check_grade_type
  validates_numericality_of :max_weekly_classes, :allow_nil => false, :greater_than => 0
  validates_numericality_of :amount,:allow_nil => true
  validates_uniqueness_of :code, :case_sensitive => false, :scope=>[:batch_id,:is_deleted] ,:if=> 'is_deleted == false'
  named_scope :for_batch, lambda { |b| { :conditions => { :batch_id => b.to_i, :is_deleted => false } } }
  named_scope :without_exams, :conditions => { :no_exams => false, :is_deleted => false }
  named_scope :active, :conditions => { :is_deleted => false }

  before_save :fa_group_valid

  def check_grade_type
    unless self.batch.nil?
      batch = self.batch
      batch.gpa_enabled? or batch.cwa_enabled?
    else
      return false
    end
  end

  def inactivate
    update_attributes(:is_deleted=>true)
    self.employees_subjects.destroy_all
  end

  def lower_day_grade
    subjects = Subject.find_all_by_elective_group_id(self.elective_group_id) unless self.elective_group_id.nil?
    selected_employee = nil
    subjects.each do |subject|
      employees = subject.employees
      employees.each do |employee|
        if selected_employee.nil?
          selected_employee = employee
        else
          selected_employee = employee if employee.max_hours_per_day.to_i < selected_employee.max_hours_per_day.to_i
        end
      end
    end
    return selected_employee
  end

  def lower_week_grade
    subjects = Subject.find_all_by_elective_group_id(self.elective_group_id) unless self.elective_group_id.nil?
    selected_employee = nil
    subjects.each do |subject|
      employees = subject.employees
      employees.each do |employee|
        if selected_employee.nil?
          selected_employee = employee
        else
          selected_employee = employee if employee.max_hours_per_week.to_i  < selected_employee.max_hours_per_week.to_i
        end
      end
    end
    return selected_employee
  end

  def no_exam_for_batch(batch_id)
    grouped_exams = GroupedExam.find_all_by_batch_id(batch_id).collect(&:exam_group_id)
    return exam_not_created(grouped_exams)
  end

  def exam_not_created(exam_group_ids)
    exams = Exam.find_all_by_exam_group_id_and_subject_id(exam_group_ids,self.id)
    if exams.empty?
      return true
    else
      return false
    end
  end

  def full_name
    "#{batch.name}-#{code}"
  end

  def self.subject_details(parameters)
    sort_order=parameters[:sort_order]
    subject_search=parameters[:subject_search]
    course_id=parameters[:course_id]
    if subject_search.nil?
      if sort_order.nil?
        subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>'name ASC')
      else
        subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>sort_order)
      end
    else
      if sort_order.nil?
        if subject_search[:elective_subject]=="1" and subject_search[:normal_subject]=="0"
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["batches.id IN (?) and elective_group_id != ? and subjects.is_deleted=?",subject_search[:batch_ids],"",false],:order=>'name ASC')
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["elective_group_id != ? and subjects.is_deleted=? and batches.is_deleted=? and batches.is_active=?","",false,false,true],:order=>'name ASC')
          end
        elsif subject_search[:elective_subject]=="0" and subject_search[:normal_subject]=="1"
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>subject_search[:batch_ids]},:elective_group_id=>nil},:order=>'name ASC')
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:elective_group_id=>nil,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>'name ASC')
          end
        else
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>subject_search[:batch_ids]}},:order=>'name ASC')
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>'name ASC')
          end
        end
      else
        if subject_search[:elective_subject]=="1" and subject_search[:normal_subject]=="0"
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["batches.id IN (?) and elective_group_id != ? and subjects.is_deleted=?",subject_search[:batch_ids],"",false],:order=>sort_order)
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["elective_group_id != ? and subjects.is_deleted=? and batches.is_deleted=? and batches.is_active=?","",false,false,true],:order=>sort_order)
          end
        elsif subject_search[:elective_subject]=="0" and subject_search[:normal_subject]=="1"
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>subject_search[:batch_ids]},:elective_group_id=>nil},:order=>sort_order)
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:elective_group_id=>nil,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>sort_order)
          end
        else
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>subject_search[:batch_ids]}},:order=>sort_order)
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>sort_order)
          end
        end
      end
    end
    data=[]
    if subject_search !=nil and subject_search[:elective_subject]=="1" and subject_search[:normal_subject]=="0"
      col_heads=["#{t('no_text')}","#{t('name')}","#{t('code') }","#{t('max_weekly_classes') }","#{t('batch_name')}","#{t('students')}","#{t('exams_text')}"]
    else
      col_heads=["#{t('no_text')}","#{t('name')}","#{t('code') }","#{t('max_weekly_classes') }","#{t('batch_name')}","#{t('elective_subject')}","#{t('exams_text')}"]
    end
    data << col_heads
    subjects.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.name}"
      col<< "#{s.code}"
      col<< "#{s.max_weekly_classes}"
      col<< "#{s.c_code}-#{s.batch_name}"
      if subject_search !=nil and subject_search[:elective_subject]=="1" and subject_search[:normal_subject]=="0"
        col<< "#{s.student_count}"
      else
        col<< "#{ s.elective_group_id==nil ? t('no_texts') : t('yes_text')}"
      end
      col<< "#{s.no_exams==true ? t('no_texts') : t('yes_text')}"
      col=col.flatten
      data<< col
    end
    return data
  end

  private

  def fa_group_valid
    fa_groups.group_by(&:cce_exam_category_id).values.each do |fg|
      if fg.length > 2
        errors.add(:fa_group, "cannot have more than 2 fa group under a single exam category")
        return false
      end
    end
  end
  
end
