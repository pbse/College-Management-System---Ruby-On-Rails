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

class Course < ActiveRecord::Base

  GRADINGTYPES = {"1"=>"GPA","2"=>"CWA","3"=>"CCE"}

  validates_presence_of :course_name, :code
  validates_uniqueness_of :code,:scope=> [:is_deleted],:if=> 'is_deleted == false'
  validate :presence_of_initial_batch, :on => :create

  has_many :batches
  has_many :batch_groups
  has_many :ranking_levels
  has_many :class_designations
  has_many :subject_amounts
  has_many :students ,:through=>:batches
  accepts_nested_attributes_for :batches
  has_and_belongs_to_many :observation_groups
  has_and_belongs_to_many_with_deferred_save :cce_weightages

  before_save :cce_weightage_valid

  named_scope :active, :conditions => { :is_deleted => false }, :order => 'course_name asc'
  named_scope :deleted, :conditions => { :is_deleted => true }, :order => 'course_name asc'
  named_scope :cce, {:select => "courses.*",:conditions=>{:grading_type => GRADINGTYPES.invert["CCE"],:is_deleted => false}, :order => 'course_name asc'}

  def presence_of_initial_batch
    errors.add_to_base :should_have_an_initial_batch if batches.length == 0
  end

  def inactivate
    update_attribute(:is_deleted, true)
  end

  def full_name
    "#{course_name} #{section_name}"
  end

  def active_batches
    self.batches.all(:conditions=>{:is_active=>true,:is_deleted=>false})
  end

  def has_batch_groups_with_active_batches
    batch_groups = self.batch_groups
    if batch_groups.empty?
      return false
    else
      batch_groups.each do|b|
        return true if b.has_active_batches==true
      end
    end
    return false
  end

  def find_course_rank(batch_ids,sort_order)
    batches = Batch.find_all_by_id(batch_ids)
    @students = Student.find_all_by_batch_id(batches)
    @grouped_exams = GroupedExam.find_all_by_batch_id(batches)
    ordered_scores = []
    student_scores = []
    ranked_students = []
    @students.each do|student|
      score = GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student.id,student.batch_id,"c")
      marks = 0
      unless score.nil?
        marks = score.marks
      end
      ordered_scores << marks
      student_scores << [student.id,marks]
    end
    ordered_scores = ordered_scores.compact.uniq.sort.reverse
    @students.each do |student|
      m = 0
      student_scores.each do|student_score|
        if student_score[0]==student.id
          m = student_score[1]
        end
      end
      if sort_order=="" or sort_order=="rank-ascend" or sort_order=="rank-descend"
        ranked_students << [(ordered_scores.index(m) + 1),m,student.id,student]
      else
        ranked_students << [student.full_name,(ordered_scores.index(m) + 1),m,student.id,student]
      end
    end
    if sort_order=="" or sort_order=="rank-ascend" or sort_order=="name-ascend"
      ranked_students = ranked_students.sort
    else
      ranked_students = ranked_students.sort.reverse
    end
  end

  def cce_enabled?
    Configuration.cce_enabled? and grading_type == "3"
  end

  def gpa_enabled?
    Configuration.has_gpa? and self.grading_type=="1"
  end

  def cwa_enabled?
    Configuration.has_cwa? and self.grading_type=="2"
  end

  def normal_enabled?
    self.grading_type.nil? or self.grading_type=="0"
  end
  #  def guardian_email_list
  #    email_addresses = []
  #    students = self.students
  #    students.each do |s|
  #      email_addresses << s.immediate_contact.email unless s.immediate_contact.nil?
  #    end
  #    email_addresses
  #  end
  #
  #  def student_email_list
  #    email_addresses = []
  #    students = self.students
  #    students.each do |s|
  #      email_addresses << s.email unless s.email.nil?
  #    end
  #    email_addresses
  #  end
  class << self
    def grading_types
      hsh =  ActiveSupport::OrderedHash.new
      hsh["0"]="Normal"
      types = Configuration.get_grading_types
      types.each{|t| hsh[t] = GRADINGTYPES[t]}
      hsh
    end
    def grading_types_as_options
      grading_types.invert.sort_by{|k,v| v}
    end
  end

  def cce_weightages_for_exam_category(cce_exam_cateogry_id)
    cce_weightages.all(:conditions=>{:cce_exam_category_id=>cce_exam_cateogry_id})
  end

  def self.course_details(parameters)
    sort_order=parameters[:sort_order]
    unless sort_order.nil?
      courses=Course.all(:select=>"courses.id,courses.course_name,courses.code,courses.section_name,count(students.id) as student_count,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,count(DISTINCT IF(batches.is_deleted=0 and batches.is_active=1,batches.id,NULL)) as batch_count",:conditions=>{:courses=>{:is_deleted=>false}},:joins=>"left outer join batches on courses.id=batches.course_id left outer join students on batches.id=students.batch_id",:group=>"courses.id",:order=>sort_order)
    else
      courses=Course.all(:select=>"courses.id,courses.course_name,courses.code,courses.section_name,count(students.id) as student_count,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,count(DISTINCT IF(batches.is_deleted=0 and batches.is_active=1,batches.id,NULL)) as batch_count",:conditions=>{:courses=>{:is_deleted=>false}},:joins=>"left outer join batches on courses.id=batches.course_id left outer join students on batches.id=students.batch_id",:group=>"courses.id",:order=>'course_name ASC')
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('code')}","#{t('section')}","#{t('batch')}","#{t('students')}","#{t('male')}","#{t('female')}"]
    data << col_heads
    courses.each_with_index do |c,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{c.course_name}"
      col<< "#{c.code}"
      col<< "#{c.section_name}"
      col<< "#{c.batch_count}"
      col<< "#{c.student_count}"
      col<< "#{c.male_count}"
      col<< "#{c.female_count}"
      col=col.flatten
      data << col
    end
    return data
  end

  def self.course_fee_defaulters(parameters)
    sort_order=parameters[:sort_order]
    if sort_order.nil?
      courses=Course.all(:select=>"courses.id,course_name,section_name,courses.code,count(DISTINCT IF(batches.is_deleted='0',batches.id,NULL)) as batch_count,sum(IF(finance_fee_collections.is_deleted='0' and batches.is_deleted='0' and students.id IS NOT NULL,finance_fees.balance,NULL)) as balance",:joins=>"LEFT OUTER JOIN `batches` ON batches.course_id = courses.id LEFT OUTER JOIN `finance_fees` ON finance_fees.batch_id = batches.id LEFT OUTER JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:group=>"courses.id",:conditions=>{:is_deleted=>false},:order=>"course_name ASC")
    else
      courses=Course.all(:select=>"courses.id,course_name,section_name,courses.code,count(DISTINCT IF(batches.is_deleted='0',batches.id,NULL)) as batch_count,sum(IF(finance_fee_collections.is_deleted='0' and batches.is_deleted='0' and students.id IS NOT NULL,finance_fees.balance,NULL)) as balance",:joins=>"LEFT OUTER JOIN `batches` ON batches.course_id = courses.id LEFT OUTER JOIN `finance_fees` ON finance_fees.batch_id = batches.id LEFT OUTER JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:group=>"courses.id",:conditions=>{:is_deleted=>false},:order=>sort_order)
    end
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      courses_transport=Course.all(:select=>"courses.id,sum(IF(transport_fee_collections.is_deleted='0' and batches.is_deleted='0' and transport_fees.transaction_id is NULL and transport_fees.receiver_type='Student' and students.id IS NOT NULL ,transport_fees.bus_fare,NULL)) as balance",:joins=>"LEFT OUTER JOIN `batches` ON batches.course_id = courses.id LEFT OUTER JOIN transport_fee_collections on transport_fee_collections.batch_id=batches.id LEFT OUTER JOIN transport_fees on transport_fees.transport_fee_collection_id=transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:group=>"courses.id",:conditions=>{:is_deleted=>false})
      courses.each do |course|
        course["balance"]=course.balance.to_f
        course_transport=courses_transport.select{|s| s.id==course.id}
        course.balance+=course_transport[0].balance.to_f
      end
    end
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      courses_hostel=Course.all(:select=>"courses.id,sum(IF(hostel_fee_collections.is_deleted='0' and batches.is_deleted='0' and hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL ,hostel_fees.rent,NULL)) as balance",:joins=>"LEFT OUTER JOIN `batches` ON batches.course_id = courses.id LEFT OUTER JOIN hostel_fee_collections on hostel_fee_collections.batch_id=batches.id LEFT OUTER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id=hostel_fee_collections.id LEFT OUTER JOIN students on students.id=hostel_fees.student_id",:group=>"courses.id",:conditions=>{:is_deleted=>false})
      courses.each do |course|
        course["balance"]=course.balance.to_f
        course_hostel=courses_hostel.select{|s| s.id==course.id}
        course.balance+=course_hostel[0].balance.to_f
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('code')}","#{t('section')}","#{t('batches_text')}","#{t('balance')}(#{Configuration.currency})"]
    data << col_heads
    courses.each_with_index do |c,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{c.course_name}"
      col<< "#{c.code}"
      col<< "#{c.section_name}"
      col<< "#{c.batch_count}"
      col<< "#{c.balance.nil?? 0.0 : c.balance}"
      col=col.flatten
      data<< col
    end
    return data
  end

  private

  def cce_weightage_valid
    cce_weightages.group_by(&:criteria_type).values.each do |v|
      unless v.collect(&:cce_exam_category_id).length == v.collect(&:cce_exam_category_id).uniq.length
        errors.add(:cce_weightages,"can't assign more than one FA or SA under a single exam category.")
        return false
      end
    end
    true

  end

end