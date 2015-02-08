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

class User < ActiveRecord::Base
  attr_accessor :password, :role, :old_password, :new_password, :confirm_password

  validates_uniqueness_of :username, :scope=> [:is_deleted],:if=> 'is_deleted == false' #, :email
  validates_length_of     :username, :within => 1..20
  validates_length_of     :password, :within => 4..40, :allow_nil => true
  validates_format_of     :username, :with => /^[A-Z0-9_-]*$/i,
    :message => :must_contain_only_letters
  validates_format_of     :email, :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i,   :allow_blank=>true,
    :message => :must_be_a_valid_email_address
  validates_presence_of   :role , :on=>:create
  validates_presence_of   :password, :on => :create
  validates_presence_of   :first_name

  has_and_belongs_to_many :privileges
  has_many  :user_events
  has_many  :events,:through=>:user_events

  has_many :user_menu_links
  has_many :menu_links, :through=>:user_menu_links

  has_one :student_entry,:class_name=>"Student",:foreign_key=>"user_id"
  has_one :guardian_entry,:class_name=>"Guardian",:foreign_key=>"user_id"
  has_one :archived_student_entry,:class_name=>"ArchivedStudent",:foreign_key=>"user_id"
  has_one :employee_entry,:class_name=>"Employee",:foreign_key=>"user_id"
  has_one :archived_employee_entry,:class_name=>"ArchivedEmployee",:foreign_key=>"user_id"
  has_one :biometric_information, :dependent => :destroy

  named_scope :active, :conditions => { :is_deleted => false }
  named_scope :inactive, :conditions => { :is_deleted => true }

  after_save :create_default_menu_links

  def before_save
    self.salt = random_string(8) if self.salt == nil
    self.hashed_password = Digest::SHA1.hexdigest(self.salt + self.password) unless self.password.nil?
    if self.new_record?
      self.admin, self.student, self.employee = false, false, false
      self.admin    = true if self.role == 'Admin'
      self.student  = true if self.role == 'Student'
      self.employee = true if self.role == 'Employee'
      self.parent = true if self.role == 'Parent'
      self.is_first_login = true
    end
  end

  def create_default_menu_links
    changes_to_be_checked = ['admin','student','employee','parent']
    check_changes = self.changed & changes_to_be_checked
    if (self.new_record? or check_changes.present?)
      self.menu_links = []
      default_links = []
      if self.admin?
        main_links = MenuLink.find_all_by_name(["human_resource","settings","students","calendar_text","news_text","event_creations"])
        default_links = default_links + main_links
        main_links.each do|link|
          sub_links = MenuLink.find_all_by_higher_link_id(link.id)
          default_links = default_links + sub_links
        end
      elsif self.employee?
        own_links = MenuLink.find_all_by_user_type("employee")
        default_links = own_links + MenuLink.find_all_by_name(["news_text","calendar_text"])
      else
        own_links = MenuLink.find_all_by_name_and_user_type(["my_profile","timetable_text","academics"],"student")
        default_links = own_links + MenuLink.find_all_by_name(["news_text","calendar_text"])
      end
      self.menu_links = default_links
    end
  end

  def delete_user_menu_caches
    Rails.cache.delete("user_quick_links#{self.id}")
    menu_cats = MenuLinkCategory.all
    menu_cats.each do|cat|
      Rails.cache.delete("user_cat_links_#{cat.id}_#{self.id}")
    end
  end


  def student_record
    self.is_deleted ? self.archived_student_entry : self.student_entry
  end

  def employee_record
    self.is_deleted ? self.archived_employee_entry : self.employee_entry
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def check_reminders
    reminders =[]
    reminders = Reminder.find(:all , :conditions => ["recipient = '#{self.id}'"])
    count = 0
    reminders.each do |r|
      unless r.is_read
        count += 1
      end
    end
    return count
  end

  def self.authenticate?(username, password)
    u = User.find_by_username username
    u.hashed_password == Digest::SHA1.hexdigest(u.salt + password)
  end

  def random_string(len)
    randstr = ""
    chars = ("0".."9").to_a + ("a".."z").to_a + ("A".."Z").to_a
    len.times { randstr << chars[rand(chars.size - 1)] }
    randstr
  end

  def role_name
    return "#{t('admin')}" if self.admin?
    return "#{t('student_text')}" if self.student?
    return "#{t('employee_text')}" if self.employee?
    return "#{t('parent')}" if self.parent?
    return nil
  end

  def role_symbols
    prv = []
    privileges.map { |privilege| prv << privilege.name.underscore.to_sym } unless @privilge_symbols

    @privilge_symbols ||= if admin?
      [:admin] + prv
    elsif student?
      [:student] + prv
    elsif employee?
      [:employee] + prv
    elsif parent?
      [:parent] + prv
    else
      prv  
    end
  end

  def is_allowed_to_mark_attendance?
    if self.employee?
      attendance_type = Configuration.get_config_value('StudentAttendanceType')
      if ((self.employee_record.subjects.present? and attendance_type == 'SubjectWise') or (self.employee_record.batches.find(:all,:conditions=>{:is_deleted=>false,:is_active=>true}).present? and attendance_type == 'Daily'))
        return true
      end
    end
    return false
  end

  def can_view_results?
    if self.employee?
      return true if self.employee_record.batches.find(:all,:conditions=>{:is_deleted=>false,:is_active=>true}).present?
    end
    return false
  end

  def has_assigned_subjects?
    if self.employee?
      employee_subjects= self.employee_record.subjects
      if employee_subjects.empty?
        return false
      else
        return true
      end
    else
      return false
    end
  end

  def clear_menu_cache
    Rails.cache.delete("user_main_menu#{self.id}")
    Rails.cache.delete("user_autocomplete_menu#{self.id}")
  end
  def clear_school_name_cache(request_host)
    Rails.cache.delete("current_school_name/#{request_host}")
  end

  def parent_record
    #    p=Student.find_by_admission_no(self.username[1..self.username.length])
    unless guardian_entry.nil?
      guardian_entry.current_ward
    else
      Student.find_by_admission_no(self.username[1..self.username.length])
    end

    #    p '-------------'
    #    p self.username[1..self.username.length]
    #     Student.find_by_sibling_no_and_immediate_contact(self.username[1..self.username.length])
    #guardian_entry.ward
  end

  def has_subject_in_batch(b)
    employee_record.subjects.collect(&:batch_id).include? b.id
  end

  def days_events(date)
    all_events=[]
    case(role_name)
    when "Admin"
      all_events=Event.find(:all,:conditions => ["? between date(events.start_date) and date(events.end_date)",date])
    when "Student"
      all_events+= events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= student_record.batch.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_common = true",date])
    when "Parent"
      all_events+= events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= parent_record.user.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= parent_record.batch.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_common = true",date])
    when "Employee"
      all_events+= events.all(:conditions=>["? between events.start_date and events.end_date",date])
      all_events+= employee_record.employee_department.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_exam = true",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_common = true",date])
    end
    all_events
  end

  def next_event(date)
    all_events=[]
    case(role_name)
    when "Admin"
      all_events=Event.find(:all,:conditions => ["? < date(events.end_date)",date],:order=>"start_date")
    when "Student"
      all_events+= events.all(:conditions=>["? < date(events.end_date)",date])
      all_events+= student_record.batch.events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_common = true",date],:order=>"start_date")
    when "Parent"
      all_events+= events.all(:conditions=>["? < date(events.end_date)",date])
      all_events+= parent_record.user.events.all(:conditions=>["? < date(events.end_date)",date])
      all_events+= parent_record.batch.events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_common = true",date],:order=>"start_date")
    when "Employee"
      all_events+= events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= employee_record.employee_department.events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_exam = true",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_common = true",date],:order=>"start_date")
    end
    start_date=all_events.collect(&:start_date).min
    unless start_date
      return ""
    else
      next_date=(start_date.to_date<=date ? date+1.days : start_date )
      next_date
    end
  end
  def soft_delete
    self.update_attributes(:is_deleted =>true)
  end

  def user_type
    admin? ? "Admin" : employee? ? "Employee" : student? ? "Student" : "Parent"
  end
  def school_details
    name=Configuration.get_config_value('InstitutionName').present? ? "#{Configuration.get_config_value('InstitutionName')}," :""
    address=Configuration.get_config_value('InstitutionAddress').present? ? "#{Configuration.get_config_value('InstitutionAddress')}," :""
    Configuration.get_config_value('InstitutionPhoneNo').present?? phone="#{' Ph:'}#{Configuration.get_config_value('InstitutionPhoneNo')}" :""
    return (name+"#{' '}#{address}"+"#{phone}").chomp(',')
  end
  def school_name
    Configuration.get_config_value('InstitutionName')
  end
end
