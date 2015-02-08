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

class WeekdayController < ApplicationController
  before_filter :login_required
  before_filter :fetch_default_weekdays
  filter_access_to :all
  before_filter :check_status
  before_filter :default_time_zone_present_time
  require 'set'

  def index
    @batches = Batch.active
    @weekday_set = WeekdaySet.first
  end

  def week
    if params[:batch_id] == ''
      @weekday_set = WeekdaySet.first
    else
      @batch  = Batch.find params[:batch_id]
      @weekday_set = @batch.weekday_set
      @weekday_set ||= WeekdaySet.first
    end
    render :update do |page|
      page.replace_html "weekdays", :partial => "weekdays"
    end
  end



  def create
    @batch =  Batch.find_by_id(params[:weekday][:batch_id])
    @weekday_set = @batch.nil? ? WeekdaySet.first : @batch.weekday_set
    weekday_set_found = nil
    flag = 0
    if request.post?
      current_timetables = Timetable.find(:all,:conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?) OR (timetables.start_date >= ? AND timetables.end_date >= ?)",@local_tzone_time.to_date,@local_tzone_time.to_date,@local_tzone_time.to_date,@local_tzone_time.to_date])
      weekday_ids = params[:weekdays].nil? ? Array.new : params[:weekdays].map(&:to_i)
      weekday_sets = WeekdaySet.all.map{|ws| [ws.id,Set.new(ws.weekday_ids)]}
      weekday_sets.each do |weekday_set|
        if weekday_set.second == Set.new(weekday_ids)
          flag = 1
          weekday_set_found = weekday_set
        end
      end
      if flag == 1
        @batch.update_attributes(:weekday_set_id => weekday_set_found.first) unless @batch.nil?
      else
        if @batch.nil?
          if(weekday_ids.blank? or TimeTableWeekday.find_by_weekday_set_id(WeekdaySet.first.try(:id)).present?)
            flash[:notice] = "Default weekdays cannot be edited"
          else   
            WeekdaySet.first.weekday_ids = weekday_ids
            flash[:notice] = "#{t('weekdays_modified')}"
          end
        else
          if weekday_ids.blank?
            @batch.update_attributes(:weekday_set_id => WeekdaySet.first.try(:id)) unless @batch.nil?
            flash[:notice] = "#{t('weekdays_modified')}"
          else
            weekday_set = WeekdaySet.create
            weekday_set.weekday_ids = weekday_ids
            @batch.update_attributes(:weekday_set_id => weekday_set.id)
            flash[:notice] = "#{t('weekdays_modified')}"
          end
        end
      end
      if @batch.present?
        current_timetables.each do |current_timetable|
          if (TimeTableWeekday.find_by_batch_id_and_timetable_id(@batch.id,current_timetable.try(:id)).nil? and current_timetable.present?)
            TimeTableWeekday.create(:batch_id => @batch.id, :timetable_id => current_timetable.try(:id), :weekday_set_id => @batch.weekday_set_id)
          end
        end
      end
    end
    redirect_to :action => "index"
  end

  private

  def fetch_default_weekdays
    @default_weekdays = WeekdaySet.default_weekdays
  end
end
