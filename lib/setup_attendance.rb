# To change this template, choose Tools | Templates
# and open the template in the editor.

class SetupAttendance
  def initialize
    
  end

  def self.setup_weekdays
    create_weekday_set = WeekdaySet.all.empty? ? WeekdaySet.new : WeekdaySet.first
    create_weekday_set.weekday_ids = Weekday.default.blank? ? [1,2,3,4,5] : Weekday.default.map{|weekday| weekday.weekday.to_i} if create_weekday_set.new_record?
    default_weekday_set = WeekdaySet.first
    flag = 0
    weekday_set_found = nil
    Batch.find_in_batches(:batch_size => 500) do|batches|
      batches.each do |batch|
        batch_weekday_set = Weekday.for_batch(batch.id).map{|weekday| weekday.weekday.to_i}
        unless batch_weekday_set.present?
          batch.update_attributes(:weekday_set_id => default_weekday_set.id)
        else
          set_batch_weekday = Set.new(batch_weekday_set)
          stored_weekday_sets = WeekdaySet.all.map{|ws| [ws.id,Set.new(ws.weekday_ids)]}
          stored_weekday_sets.each do |weekday_set|
            if weekday_set.second == set_batch_weekday
              flag = 1
              weekday_set_found = weekday_set
            end
          end
          if flag == 1
            batch.update_attributes(:weekday_set_id => weekday_set_found.first)
          else
            weekday_set = WeekdaySet.create
            weekday_set.weekday_ids = batch_weekday_set
            batch.update_attributes(:weekday_set_id => weekday_set.id)
          end
        end
      end
    end
  end

  def self.setup_class_timings
    default_class_timings = ClassTiming.find(:all,:conditions => { :batch_id => nil,:is_deleted=>false}, :order =>'start_time ASC')
    default_class_timing_set = ClassTimingSet.create(:name => "Default")
    default_class_timings.map{|dct| dct.update_attributes(:class_timing_set_id => default_class_timing_set.id)}
    Batch.find_in_batches(:batch_size => 500, :include => [:class_timings]) do |batches|
      batches.each do |batch|
        batch_class_timings = batch.class_timings
        if batch_class_timings.empty?
          batch.update_attributes(:class_timing_set_id => default_class_timing_set.id)
        else
          batch_class_timing_set = ClassTimingSet.create(:name => "#{batch.full_name}")
          batch_class_timings.map{|bct| bct.update_attributes(:class_timing_set_id => batch_class_timing_set.id)}
          batch.update_attributes(:class_timing_set_id => batch_class_timing_set.id)
        end
      end
    end
  end

  def self.setup_timetable
    timetable_weekday_inserts = Array.new
    timetable_class_timing_inserts = Array.new
    TimetableEntry.find_in_batches(:batch_size => 500, :include => [:weekday]) do |timetable_entries|
      timetable_entries.each do |timetable_entry|
        timetable_entry.update_attributes(:weekday_id => timetable_entry.weekday.try(:weekday))
      end
    end
    if(MultiSchool rescue nil)
      school = MultiSchool.current_school
      timetable_weekday_inserts = Array.new
      timetable_class_timing_inserts = Array.new
      Timetable.find_in_batches(:batch_size => 100) do |timetables|
        timetables.each do |timetable|
          Batch.find_in_batches(:batch_size => 500, :include => [:class_timing_set,:weekday_set]) do |batches|
            batches.each do |batch|
              timetable_weekday_inserts << "(#{timetable.id}, #{batch.id}, '#{batch.weekday_set.try(:id)}','#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}', '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}', #{school.id})"
              timetable_class_timing_inserts << "(#{timetable.id}, #{batch.id}, '#{batch.class_timing_set.try(:id)}','#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}', '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}', #{school.id})"
            end
            if(Timetable.all.present? and Batch.all.present?)
              insert_weekday_sql = "INSERT INTO time_table_weekdays (`timetable_id` ,`batch_id` ,`weekday_set_id` ,`created_at` ,`updated_at`,`school_id`) VALUES #{timetable_weekday_inserts.join(', ')} ;"
              insert_class_timing_sql = "INSERT INTO time_table_class_timings (`timetable_id` ,`batch_id` ,`class_timing_set_id` ,`created_at` ,`updated_at`,`school_id`) VALUES #{timetable_class_timing_inserts.join(', ')} ;"
              ActiveRecord::Base.connection.execute(insert_weekday_sql)
              ActiveRecord::Base.connection.execute(insert_class_timing_sql)
            end
          end
        end
      end
    else
      
      Timetable.find_in_batches(:batch_size => 100) do |timetables|
        timetables.each do |timetable|
          Batch.find_in_batches(:batch_size => 500, :include => [:class_timing_set,:weekday_set]) do |batches|
            timetable_weekday_inserts = Array.new
            timetable_class_timing_inserts = Array.new
            batches.each do |batch|
              timetable_weekday_inserts << "(#{timetable.id}, #{batch.id}, #{batch.weekday_set.try(:id)}, '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}', '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}', NULL)"
              timetable_class_timing_inserts << "(#{timetable.id}, #{batch.id}, #{batch.class_timing_set.try(:id)}, '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}', '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}',NULL)"
            end
            if(Timetable.all.present? and Batch.all.present?)
              insert_weekday_sql = "INSERT INTO time_table_weekdays (`timetable_id` ,`batch_id` ,`weekday_set_id` ,`created_at` ,`updated_at`,`school_id`) VALUES #{timetable_weekday_inserts.join(', ')} ;"
              insert_class_timing_sql = "INSERT INTO time_table_class_timings (`timetable_id` ,`batch_id` ,`class_timing_set_id` ,`created_at` ,`updated_at`,`school_id`) VALUES #{timetable_class_timing_inserts.join(', ')} ;"
              ActiveRecord::Base.connection.execute(insert_weekday_sql)
              ActiveRecord::Base.connection.execute(insert_class_timing_sql)
            end
          end
        end
      end
    end
    
  end
end





