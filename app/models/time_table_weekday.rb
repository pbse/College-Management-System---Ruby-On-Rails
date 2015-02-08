class TimeTableWeekday < ActiveRecord::Base
  belongs_to :batch
  belongs_to :timetable
  belongs_to :weekday_set

  validates_presence_of :batch_id, :timetable_id, :weekday_set_id
end
