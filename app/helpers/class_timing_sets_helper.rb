module ClassTimingSetsHelper
  def allowed_class_timing_set_delete(class_timing_set)
    TimetableEntry.exists?(:class_timing_id => class_timing_set.class_timing_ids)
  end

  def allowed_class_timing_delete(class_timing)
    TimetableEntry.exists?(:class_timing_id => class_timing.id)
  end
end

