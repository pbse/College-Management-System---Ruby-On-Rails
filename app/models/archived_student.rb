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

class ArchivedStudent < ActiveRecord::Base

  include CceReportMod
  
  belongs_to :country
  belongs_to :batch
  belongs_to :student_category
  belongs_to :nationality, :class_name => 'Country'
  belongs_to :user
  #has_many :archived_guardians, :foreign_key => 'ward_id', :dependent => :destroy
  has_many   :archived_guardians, :foreign_key => 'ward_id', :primary_key=>:sibling_id, :dependent => :destroy
  has_one :immediate_contact

  has_many   :students_subjects, :primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :subjects ,:through => :students_subjects
  
  has_many   :cce_reports, :primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :assessment_scores, :primary_key=>:former_id, :foreign_key=>'student_id'
  has_many   :exam_scores, :primary_key=>:former_id, :foreign_key=>'student_id'

  before_save :is_active_false

  #has_and_belongs_to_many :graduated_batches, :class_name => 'Batch', :join_table => 'batch_students',:foreign_key => 'student_id' ,:finder_sql =>'SELECT * FROM `batches`,`archived_students`  INNER JOIN `batch_students` ON `batches`.id = `batch_students`.batch_id WHERE (`batch_students`.student_id = `archived_students`.former_id )'

  has_attached_file :photo,
    :styles => {
    :thumb=> "100x100#",
    :small  => "150x150>"},
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension"

  def is_active_false
    unless self.is_active==0
      self.is_active=0
    end
  end

  def gender_as_text
    self.gender == 'm' ? 'Male' : 'Female'
  end

  def first_and_last_name
    "#{first_name} #{last_name}"
  end

  def full_name
    "#{first_name} #{middle_name} #{last_name}"
  end

  def immediate_contact
    ArchivedGuardian.find(self.immediate_contact_id) unless self.immediate_contact_id.nil?
  end

  def all_batches
    self.graduated_batches + self.batch.to_a
  end

  def graduated_batches
    # SELECT * FROM `batches` INNER JOIN `batch_students` ON `batches`.id = `batch_students`.batch_id
    Batch.find(:all,:conditions=> ["batch_students.student_id = #{former_id.to_i}"], :joins =>'INNER JOIN batch_students ON batches.id = batch_students.batch_id' )
  end

  def additional_detail(additional_field)
    StudentAdditionalDetail.find_by_additional_field_id_and_student_id(additional_field,self.former_id)
  end

  def has_retaken_exam(subject_id)
    retaken_exams = PreviousExamScore.find_all_by_student_id(self.former_id)
    if retaken_exams.empty?
      return false
    else
      exams = Exam.find_all_by_id(retaken_exams.collect(&:exam_id))
      if exams.collect(&:subject_id).include?(subject_id)
        return true
      end
      return false
    end

  end
  def siblings
    @siblings ||= (self.class.find_all_by_sibling_id(sibling_id) - [self])
  end

  def self.former_students_details(parameters)
    sort_order=parameters[:sort_order]
    former_students=parameters[:former_students]
    unless former_students.nil?
      if sort_order.nil?
        students=ArchivedStudent.all(:select=>"first_name,last_name,middle_name,admission_no,admission_date,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:created_at=>former_students[:from].to_date.beginning_of_day..former_students[:to].to_date.end_of_day}},:order=>'first_name ASC')
      else
        students=ArchivedStudent.all(:select=>"first_name,last_name,middle_name,admission_no,admission_date,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:created_at=>former_students[:from].to_date.beginning_of_day..former_students[:to].to_date.end_of_day}},:order=>sort_order)
      end
    else
      if sort_order.nil?
        students=ArchivedStudent.all(:select=>"first_name,last_name,middle_name,admission_no,admission_date,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:created_at=> Date.today.beginning_of_day..Date.today.end_of_day}},:order=>'first_name ASC')
      else
        students=ArchivedStudent.all(:select=>"first_name,last_name,middle_name,admission_no,admission_date,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:created_at=> Date.today.beginning_of_day..Date.today.end_of_day}},:order=>sort_order)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('admission_no') }","#{t('admission_date') }","#{t('leaving_date') }","#{t('batch_name')}","#{t('course_name')}","#{t('gender')}"]
    data << col_heads
    students.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.full_name}"
      col<< "#{s.admission_no}"
      col<< "#{s.admission_date}"
      col<< "#{s.created_at.to_date}"
      col<< "#{s.batch_name}"
      col<< "#{s.course_name} #{s.code} #{s.section_name}"
      col<< "#{s.gender.downcase=='m' ? t('m') : t('f')}"
      col=col.flatten
      data<< col
    end
    return data
  end
  
end