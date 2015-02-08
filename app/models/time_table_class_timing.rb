class TimeTableClassTiming < ActiveRecord::Base
  belongs_to :batch
  belongs_to :timetable
  belongs_to :class_timing_set

  validates_presence_of :batch_id, :timetable_id, :class_timing_set_id
end
