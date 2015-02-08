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

class Guardian < ActiveRecord::Base
  belongs_to :country
  belongs_to :ward, :class_name => 'Student', :foreign_key=>:sibling_id
  belongs_to :user
  has_many   :wards,:class_name => 'Student', :foreign_key => 'sibling_id', :primary_key=>:ward_id

  validates_presence_of :first_name, :relation,:ward_id
  validates_format_of     :email, :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i,   :allow_blank=>true,
    :message => :must_be_a_valid_email_address
  before_destroy :immediate_contact_nil
  before_validation :email_strip
  #after_create :set_sibling_id

  def email_strip
    self.email = self.email.strip if email
  end

  def validate
    errors.add(:dob, :cant_be_a_future_date) if self.dob > Date.today unless self.dob.nil?
  end

  def is_immediate_contact?
    ward.immediate_contact_id == id
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def archive_guardian(archived_student,id)
    student=Student.find(id)
    guardian_attributes = self.attributes
    #guardian_attributes.merge!(:sibling_id=>student.sibling_id)
    #guardian_attributes.merge!(:former_id=>self.id)
    guardian_attributes.delete "id"
    guardian_attributes.delete "user_id"
    guardian_attributes["ward_id"] = student.sibling_id
    if d=ArchivedGuardian.create(guardian_attributes)
      # guardian_attributes.delete "ward_id"
      #d.update_attributes(guardian_attributes)
      if student.all_siblings.empty?
        self.user.soft_delete if self.user.present?
        self.destroy
        #      else
        #        self.update_attributes(:ward_id=>student.siblings.select{|w| w.id!=id}.first.id)
        #        update_attributes(:sibling_id=>ward_id)
        #        Student.update_all({:sibling_id=>ward_id},{:id=>student.siblings.collect(&:id)})
        #self.update_attributes(:ward_id=>Student.find(:first,:conditions=>("id=#{archived_student.sibling_id}" or "sybling_id=#{archived_student.sibling_id}" )))
      end
    end
  end

  def create_guardian_user(student)
    user = User.new do |u|
      u.first_name = self.first_name
      u.last_name = self.last_name
      u_name="p"+student.admission_no.to_s
      begin
        user_record=User.find_by_username(u_name)
        if user_record.present?
          u_name=u_name.next
        end
      end while user_record.present?
      u.username = u_name
      u.password = "#{u_name}123"
      u.role = 'Parent'
      u.email = ( email == '' or User.active.find_by_email(self.email) ) ? self.email.to_s : ""
    end
    self.update_attributes(:user_id => user.id) if user.save
  end



  def self.shift_user(student)
    current_student=Student.find(student.id)
    current_guardian =  student.immediate_contact
    Guardian.find(:all,:conditions=>"ward_id=#{current_student.sibling_id}").each do |g|
      #student.guardians.each do |g|

      unless (student.all_siblings).collect(&:immediate_contact_id).include?(g.id)

        parent_user = g.user
        parent_user.soft_delete if parent_user.present? and (parent_user.is_deleted==false)and ((current_guardian.present? ) and current_guardian!=g)
        #parent_user.soft_delete if parent_user.present? and (parent_user.is_deleted==false) and ((current_guardian.present? and current_guardian.user.present?) and current_guardian.user!=parent_user)

      end
    end

    if current_guardian.present?
      if current_guardian.user.present?
        current_guardian.user.update_attribute(:is_deleted,false) if current_guardian.user.is_deleted
      else
        current_guardian.create_guardian_user(student)
      end
    end
  end

  def immediate_contact_nil
    student = self.current_ward
    if student.present? and (student.immediate_contact_id==self.id)
      student.update_attribute(:immediate_contact_id,nil)
    end
  end

  def current_ward
    #Student.find_by_id_and_immediate_contact_id(current_ward_id,id)
    Student.find(:first,:conditions=>["id=? and immediate_contact_id=?",current_ward_id,id])

  end
  def current_ward_id
    (Fedena.present_student_id.present? and wards.collect(&:id).include?((Fedena.present_student_id).to_i)) ? student=Student.find(Fedena.present_student_id) : student=nil
    if (student.present? and student.immediate_contact_id==id)
      Fedena.present_student_id
    else
      wards.select{|w| w.immediate_contact_id==id}.first.id
    end
  end
  def set_sibling_id
    update_attribute(:sibling_id,id)
  end
end
