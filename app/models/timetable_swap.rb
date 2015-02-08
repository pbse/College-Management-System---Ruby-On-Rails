class TimetableSwap < ActiveRecord::Base
  validates_uniqueness_of :date, :scope => [:timetable_entry_id, :employee_id,:subject_id]
  validates_presence_of :employee_id,:subject_id,:timetable_entry_id
  belongs_to :employee
  belongs_to :subject
  belongs_to :timetable_entry
  before_save :present_subject_attendacne_check
  before_update :swaped_subject_attendance_check
  before_destroy :swaped_subject_attendance_check

  def validate
    timetable_entry = TimetableEntry.find(self.timetable_entry_id)
    if self.employee_id == timetable_entry.employee_id and self.subject_id == timetable_entry.subject_id
      errors.add_to_base :same_employee_assigned
      return false
    else
      return true
    end
  end

  def present_subject_attendacne_check
    timetable_entry = TimetableEntry.find(self.timetable_entry_id)
    subject_leave= SubjectLeave.all(:conditions=>{:month_date=>self.date,:subject_id=>timetable_entry.subject_id,:class_timing_id=>timetable_entry.class_timing_id,:batch_id=>timetable_entry.batch_id})
    unless subject_leave.empty?
      errors.add_to_base :present_subject_having_attendance
      return false
    else
      return true
    end
  end
  def swaped_subject_attendance_check
    timetable_swap=TimetableSwap.find self.id
    timetable_entry=timetable_swap.timetable_entry
    subject_leave= SubjectLeave.all(:conditions=>{:month_date=>timetable_swap.date,:subject_id=>timetable_swap.subject_id,:class_timing_id=>timetable_entry.class_timing_id,:batch_id=>timetable_entry.batch_id})
    unless subject_leave.empty?
      errors.add_to_base :swaped_subject_having_attendance
      return false
    else
      return true
    end
  end

end
