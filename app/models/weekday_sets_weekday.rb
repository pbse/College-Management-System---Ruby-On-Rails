class WeekdaySetsWeekday < ActiveRecord::Base
  belongs_to :weekday
  belongs_to :weekday_set
end
