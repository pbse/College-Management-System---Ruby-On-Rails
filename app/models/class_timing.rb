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

class ClassTiming < ActiveRecord::Base
  belongs_to :class_timing_set
  has_many :timetable_entries, :dependent=>:destroy
  belongs_to :batch

  validates_presence_of :name
  validates_uniqueness_of :name,  :scope => [:is_deleted,:class_timing_set_id]


  named_scope :default, :conditions => { :batch_id => nil, :is_break => false, :is_deleted=>false  }, :order =>'start_time ASC'
  named_scope :active, :conditions => {:is_deleted=>false  }, :order =>'start_time ASC'
  named_scope :timetable_timings, :conditions => {:is_deleted => false, :is_break => false}, :order => 'start_time ASC'

  def validate
    errors.add(:end_time, :should_be_later) \
      if self.start_time > self.end_time \
      unless self.start_time.nil? or self.end_time.nil?
    start_overlap = class_timing_set.class_timings.find(:all,:conditions=>["start_time < ? and end_time > ? and is_deleted = ?", start_time,start_time,false]).reject{|ct| ct.id == id}.present?
    end_overlap = class_timing_set.class_timings.find(:all,:conditions=>["start_time < ? and end_time > ? and is_deleted = ?", end_time,end_time,false]).reject{|ct| ct.id == id}.present?
    between_overlap = class_timing_set.class_timings.find(:all,:conditions=>["start_time < ? and end_time > ? and is_deleted = ? ",end_time, start_time,false]).reject{|ct| ct.id == id}.present?
    errors.add(:start_time, :overlap_existing_class_timing) if start_overlap
    errors.add(:end_time, :overlap_existing_class_timing) if end_overlap
    errors.add_to_base:class_time_overlaps_with_existing if between_overlap
    errors.add(:start_time,:is_same_as_end_time) if self.start_time == self.end_time
  end
end
