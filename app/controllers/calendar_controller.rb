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

class CalendarController < ApplicationController
  before_filter :login_required
  before_filter :default_time_zone_present_time
  filter_access_to :event_delete
  def index
    privilege = current_user.privileges.map{|p| p.name}
    @user = current_user
    if params[:new_month].nil?
      @show_month = @local_tzone_time.to_date
    else
      passed_date = (params[:passed_date]).to_date
      if params[:new_month].to_i > passed_date.month
        @show_month  = passed_date+1.month
      else
        @show_month = passed_date-1.month
      end
    end
    @start_date = @show_month.beginning_of_month
    @start_date_day = @start_date.wday
    @last_day = @show_month.end_of_month
    @notifications = Hash.new{|h,k| h[k]=Array.new}
    first_day = @show_month.beginning_of_month
    last_day =  @show_month.end_of_month
    if @user.admin? or privilege.include?("EventManagement")
      @events = Event.find(:all,:conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day],:include=>[:origin])
    end
    if @user.employee? and !privilege.include?("EventManagement")
      @events = Event.find(:all,:conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day],:include=>[:origin,:employee_department_events]) 
    end
    if @user.student? or @user.parent?
      @events = Event.find(:all,:conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day],:include=>[:origin,:batch_events])  
    end
    load_notifications
  end

  def new_calendar
    @user = current_user
    d = params[:new_month].to_i
    passed_date = (params[:passed_date]).to_date
    if params[:new_month].to_i > passed_date.month
      @show_month  = passed_date+1.month
    else
      @show_month = passed_date-1.month
    end
    @start_date = @show_month.beginning_of_month
    @start_date_day = @start_date.wday
    @last_day = @show_month.end_of_month
    @notifications = Hash.new{|h,k| h[k]=Array.new}
    first_day = @show_month.beginning_of_month
    last_day =  @show_month.end_of_month
    @events = Event.find(:all,:conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day])
    load_notifications
    render :update do |page|
      page.replace_html 'calendar', :partial => 'month',:object => @show_month
      page.replace_html :tooltip_header, :text => ''
    end
  end



  def show_event_tooltip
    privilege = current_user.privileges.map{|p| p.name}
    @user = current_user
    @date = params[:id].to_date
    first_day = @date.beginning_of_month.to_time
    last_day = @date.end_of_month.to_time

    common_event = Event.find_all_by_is_common_and_is_holiday(true,false, :conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day])
    non_common_events = Event.find_all_by_is_common_and_is_holiday_and_is_exam_and_is_due(false,false,false,false, :conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day])
    @common_event_array = []
    common_event.each do |h|
      if h.start_date.to_date == h.end_date.to_date
        @common_event_array.push h if h.start_date.to_date == @date
      else
        (h.start_date.to_date..h.end_date.to_date).each do |d|
          @common_event_array.push h if d == @date
        end
      end
    end
    if @user.student == true or @user.parent == true
      non_common_events = Event.find_all_by_is_common_and_is_holiday_and_is_exam_and_is_due(false,false,false,false, :conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day],:include=>[:batch_events])
      user_student = @user.student_record if @user.student
      user_student = @user.parent_record if @user.parent
      batch = user_student.batch
      @student_batch_not_common_event_array = []
      non_common_events.each do |h|
        student_batch_event = h.batch_events.select{|event| event.batch_id==batch.id}.first
        if h.start_date.to_date == "#{h.end_date.year}-#{h.end_date.month}-#{h.end_date.day}".to_date
          if "#{h.start_date.year}-#{h.start_date.month}-#{h.start_date.day}".to_date == @date
            @student_batch_not_common_event_array.push(h) unless student_batch_event.nil?
            if FedenaPlugin.can_access_plugin?("fedena_placement")
              if user_student.placementevents.collect(&:id).include? h.origin_id
                @student_batch_not_common_event_array.push(h)
              end
            end
          end
        else
          (h.start_date.to_date..h.end_date.to_date).each do |d|
            if d == @date
              @student_batch_not_common_event_array.push(h) unless student_batch_event.nil?
              if FedenaPlugin.can_access_plugin?("fedena_placement")
                if user_student.placementevents.collect(&:id).include? h.origin_id
                  @student_batch_not_common_event_array.push(h)
                end
              end
            end
          end
        end
      end
      @events = @common_event_array + @student_batch_not_common_event_array
    elsif @user.employee == true and !privilege.include?("EventManagement")
      non_common_events = Event.find_all_by_is_common_and_is_holiday_and_is_exam_and_is_due(false,false,false,false, :conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day],:include=>[:employee_department_events])      
      user_employee = @user.employee_record
      department = user_employee.employee_department
      @employee_dept_not_common_event_array = []
      non_common_events.each do |h|
        if (h.origin_type.nil? or (!h.origin.nil?))
          employee_dept_event = h.employee_department_events.select{|event| event.employee_department_id==department.id}.first unless department.id.nil?
          if h.start_date.to_date == h.end_date.to_date
            if h.start_date.to_date == @date
              @employee_dept_not_common_event_array.push(h) unless employee_dept_event.nil?
              @employee_dept_not_common_event_array.push(h) if privilege.include? "PlacementActivities" and h.origin.class.name=="Placementevent"
            end
          else
            (h.start_date.to_date..h.end_date.to_date).each do |d|
              if d == @date
                @employee_dept_not_common_event_array.push(h) unless employee_dept_event.nil?
                @employee_dept_not_common_event_array.push(h) if privilege.include? "PlacementActivities" and h.origin.class.name=="Placementevent"
              end
            end
          end
        end
      end
      @events = @common_event_array + @employee_dept_not_common_event_array
    elsif @user.admin == true or privilege.include?("EventManagement")
      non_common_events = Event.find_all_by_is_common_and_is_holiday_and_is_exam_and_is_due(false,false,false,false, :conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day])
      
      @employee_dept_not_common_event_array = []
      non_common_events.each do |h|
        if (h.origin_type.nil? or (!h.origin.nil?))
          employee_dept_event = h.employee_department_events
          if h.start_date.to_date == h.end_date.to_date
            if h.start_date.to_date == @date
              @employee_dept_not_common_event_array.push(h) unless employee_dept_event.nil?
            end
          else
            (h.start_date.to_date..h.end_date.to_date).each do |d|
              if d == @date
                @employee_dept_not_common_event_array.push(h) unless employee_dept_event.nil?
              end
            end
          end
        end
      end
      @events = @common_event_array + @employee_dept_not_common_event_array
    end
  end

  def show_holiday_event_tooltip
    privilege = current_user.privileges.map{|p| p.name}
    @user = current_user
    @date = params[:id].to_date
    first_day = @date.beginning_of_month.to_time
    last_day = @date.end_of_month.to_time

    common_holiday_event = Event.find_all_by_is_common_and_is_holiday(true,true, :conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day])
    non_common_holiday_events = Event.find_all_by_is_common_and_is_holiday(false,true, :conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day],:include=>[:batch_events,:employee_department_events])
    @common_holiday_event_array = []
    common_holiday_event.each do |h|
      if h.start_date.to_date == h.end_date.to_date
        @common_holiday_event_array.push h if h.start_date.to_date == @date
      else
        ( h.start_date.to_date..h.end_date.to_date).each do |d|
          @common_holiday_event_array.push h if d == @date
        end
      end
    end
    if @user.student == true or @user.parent == true
      user_student = @user.student_record if @user.student
      user_student = @user.parent_record if @user.parent
      batch = user_student.batch unless user_student.nil?
      @student_batch_not_common_holiday_event_array = []
      non_common_holiday_events.each do |h|
        student_batch_holiday_event = h.batch_events.select{|event| event.batch_id==batch.id}
        if h.start_date.to_date == h.end_date.to_date
          if h.start_date.to_date == @date
            @student_batch_not_common_holiday_event_array.push(h) unless student_batch_holiday_event.nil?
          end
        else
          (h.start_date.to_date..h.end_date.to_date).each do |d|
            if d == @date
              @student_batch_not_common_holiday_event_array.push(h) unless student_batch_holiday_event.nil?
            end
          end
        end
      end
      @events = @common_holiday_event_array.to_a + @student_batch_not_common_holiday_event_array.to_a
    elsif  @user.employee == true and !privilege.include?("EventManagement")
      user_employee = @user.employee_record
      department = user_employee.employee_department unless user_employee.nil?
      @employee_dept_not_common_holiday_event_array = []
      non_common_holiday_events.each do |h|
        employee_dept_holiday_event = h.employee_department_events.select{|event| event.employee_department_id==department.id}
        if h.start_date.to_date == h.end_date.to_date
          if h.start_date.to_date == @date
            @employee_dept_not_common_holiday_event_array.push(h) unless employee_dept_holiday_event.nil?
          end
        else
          (h.start_date.to_date..h.end_date.to_date).each do |d|
            if d == @date
              @employee_dept_not_common_holiday_event_array.push(h) unless employee_dept_holiday_event.nil?
            end
          end
        end
      end
      @events = @common_holiday_event_array.to_a + @employee_dept_not_common_holiday_event_array.to_a
    elsif  @user.admin == true or privilege.include?("EventManagement")
      @employee_dept_not_common_holiday_event_array = []
      non_common_holiday_events.each do |h|
        employee_dept_holiday_event = h.employee_department_events
        if h.start_date.to_date == h.end_date.to_date
          if h.start_date.to_date == @date
            @employee_dept_not_common_holiday_event_array.push(h) unless employee_dept_holiday_event.nil?
          end
        else
          (h.start_date.to_date..h.end_date.to_date).each do |d|
            if d == @date
              @employee_dept_not_common_holiday_event_array.push(h) unless employee_dept_holiday_event.nil?
            end
          end
        end
      end
      @events = @common_holiday_event_array.to_a + @employee_dept_not_common_holiday_event_array.to_a
    end
  end

  def show_exam_event_tooltip
    @user = current_user
    @date = params[:id].to_date
    first_day = @date.beginning_of_month.to_time
    last_day = @date.end_of_month.to_time
    @student_batch_exam_event_array = []
    subject_ids = []
    if @user.student == true or @user.parent == true
      not_common_exam_event = Event.find_all_by_is_common_and_is_holiday_and_is_exam(false,false,true, :conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day],:include=>[:origin,:batch_events])      
      user_student = @user.student_record if @user.student
      user_student = @user.parent_record if @user.parent
      subject_ids = user_student.subject_ids
      subject_ids = subject_ids << user_student.batch.subjects.collect{|x| x.id if x.elective_group_id==nil}.compact
      subject_ids = subject_ids.flatten
      not_common_exam_event.reject! { |x|x.origin.nil? or ! subject_ids.include? x.origin.subject_id }
      batch = user_student.batch
      not_common_exam_event.each do |h|
        student_batch_exam_event = h.batch_events.select{|event| event.batch_id==batch.id}
        if h.start_date.to_date == h.end_date.to_date
          if h.start_date.to_date == @date
            @student_batch_exam_event_array.push h unless student_batch_exam_event.empty?
          end
        else
          (h.start_date.to_date..h.end_date.to_date).each do |d|
            if d == @date
              @student_batch_exam_event_array.push h unless student_batch_exam_event.empty?
            end
          end
        end
      end
    else
      not_common_exam_event = Event.find_all_by_is_common_and_is_holiday_and_is_exam(false,false,true, :conditions => ["(start_date >= ? and end_date <= ?) or (start_date <= ? and end_date <= ?)  or (start_date>=? and end_date>=?) or (start_date<=? and end_date>=?) ", first_day, last_day, first_day,last_day, first_day,last_day,first_day,last_day],:include=>[:origin])
      not_common_exam_event.reject! { |x|x.origin.nil?  }
      not_common_exam_event.each do |h|
        if  h.start_date.to_date == h.end_date.to_date
          @student_batch_exam_event_array.push h  if h.start_date.to_date == @date
        else
          (h.start_date.to_date..h.end_date.to_date).each do |d|
            @student_batch_exam_event_array.push h  if d == @date
          end
        end
      end
    end
  end

  def show_due_tooltip
    privilege = current_user.privileges.map{|p| p.name}
    @user = current_user
    @date = params[:id].to_date
    finance_due_check = Event.find_all_by_is_due(true,true, :conditions => " events.start_date >= '#{@date.strftime("%Y-%m-%d 00:00:00")}' AND events.start_date <= '#{@date.strftime("%Y-%m-%d 23:59:59")}'")
    finance_due_check.reject!{|x| !x.is_active_event }
    if @user.student? or @user.parent?
      finance_due_check.reject!{|x| !x.is_student_event(@user.student_record) } if @user.student
      finance_due_check.reject!{|x| !x.is_student_event(@user.parent_record) } if @user.parent
    elsif @user.employee? and !privilege.include?("EventManagement")
      finance_due_check.reject!{|x| !x.is_employee_event(@user) }
    end
    @finance_due = []
    finance_due_check=Hash[*(finance_due_check).map {|obj| [obj.created_at.strftime("%Y-%m-%d-%H-%M"), obj]}.flatten].values
    finance_due_check.each do |h|
      if h.start_date.to_date == h.end_date.to_date
        @finance_due.push h
      end
    end
  end

  def event_delete
    @event = Event.find_by_id(params[:id])
    @event.destroy unless @event.nil?
    redirect_to :controller=>"calendar"
  end


  private

  def build_common_events_hash(e,key,today)
    if e.start_date.to_date == e.end_date.to_date
      @notifications["#{key}"] << e.start_date.to_date
    else
      (e.start_date.to_date..e.end_date.to_date).each do |d|
        @notifications["#{key}"] << d.to_date
      end
    end
  end

  def build_student_events_hash(h,key,batch_id,today)
    if h.start_date.to_date == h.end_date.to_date
      student_batch_event = h.batch_events.select{|event| event.batch_id==batch_id}.first
      @notifications["#{key}"]  << h.start_date.to_date unless student_batch_event.nil?
    else
      (h.start_date.to_date..h.end_date.to_date).each do |d|
        student_batch_event =h.batch_events.select{|event| event.batch_id==batch_id}.first
        @notifications["#{key}"]  << d.to_date unless student_batch_event.nil?
      end
    end
  end

  def  build_student_placement_hash(h,key,student,today)
    if FedenaPlugin.can_access_plugin?("fedena_placement")
      if h.start_date.to_date == h.end_date.to_date
        if student.placementevents.collect(&:id).include? h.origin_id
          @notifications["#{key}"]  << h.start_date.to_date
        end
      else
        (h.start_date.to_date..h.end_date.to_date).each do |d|
          if student.placementevents.collect(&:id).include? h.origin_id
            @notifications["#{key}"]  << h.start_date.to_date
          end
        end
      end
    end
  end
  def build_employee_placement_hash(h,key)
    if h.origin.class.name== "Placementevent"
      if h.start_date.to_date == h.end_date.to_date
        @notifications["#{key}"]  << h.start_date.to_date
      else
        (h.start_date.to_date..h.end_date.to_date).each do |d|
          @notifications["#{key}"]  << h.start_date.to_date
        end
      end
    end
  end

  def build_employee_events_hash(h,key,department_id,today)
    if h.start_date.to_date == h.end_date.to_date
      employee_dept_event = h.employee_department_events.select{|event| event.employee_department_id==department_id}.first unless department_id.nil?
      @notifications["#{key}"]  << h.start_date.to_date unless employee_dept_event.nil?
    else
      employee_dept_event = h.employee_department_events.select{|event| event.employee_department_id==department_id}.first unless department_id.nil?
      (h.start_date.to_date..h.end_date.to_date).each do |d|
        @notifications["#{key}"]  << d.to_date unless employee_dept_event.nil?
      end
    end
  end

  def load_notifications
    privilege = current_user.privileges.map{|p| p.name}
    @events.each do |e|
      #common events and holidays
      if e.is_common ==true
        if e.is_holiday == true
          build_common_events_hash(e,'common_holidays',@show_month)
        else
          build_common_events_hash(e,'common_events',@show_month)
        end
      end
      #finance dues
      if e.is_due == true
        if e.is_active_event
          if @user.admin? or privilege.include?("EventManagement")
            build_common_events_hash(e,'finance_due',@show_month)
          elsif @user.student? or @user.parent?
            student= @user.student_record if @user.student
            student= @user.parent_record if @user.parent
            if e.is_student_event(student)
              build_common_events_hash(e,'finance_due',@show_month)
            end
          elsif @user.employee?
            if e.is_employee_event(@user)
              build_common_events_hash(e,'finance_due',@show_month)
            end
          end
        end
      end

      if e.is_common ==false and e.is_holiday==false and e.is_exam==false and e.is_due==false   #not_common_event
        
        build_student_events_hash(e,'student_batch_not_common',@user.student_record.batch_id,@show_month) if @user.student?
        unless e.origin.nil?
          build_student_placement_hash(e,'student_batch_not_common',@user.student_record,@show_month) if @user.student?
          build_student_placement_hash(e, 'student_batch_not_common', Student.find(session[:student_id]),@show_month) if @user.parent?
        end
        build_student_events_hash(e,'student_batch_not_common',@user.parent_record.batch_id,@show_month) if @user.parent?
        build_employee_events_hash(e,'employee_dept_not_common',@user.employee_record.employee_department_id,@show_month) if @user.employee?
        unless e.origin.nil?
          build_employee_placement_hash(e,'employee_dept_not_common') if privilege.include?"PlacementActivities"
        end
      end

      if e.is_common ==false and e.is_holiday==true     # not_common_holiday_event
        build_student_events_hash(e,'student_batch_not_common_holiday',@user.student_record.batch_id,@show_month) if @user.student?
        build_student_events_hash(e,'student_batch_not_common_holiday',@user.parent_record.batch_id,@show_month) if @user.parent?
        build_employee_events_hash(e,'employee_dept_not_common_holiday',@user.employee_record.employee_department_id,@show_month) if @user.employee?
        if @user.admin? or privilege.include?("EventManagement")
          employee_dept_holiday_event = e.employee_department_events
          if e.start_date.to_date == e.end_date.to_date
            @notifications['employee_dept_not_common_holiday'].push e.start_date.to_date unless  employee_dept_holiday_event.nil?
          else
            (e.start_date.to_date..e.end_date.to_date).each do |d|
              @notifications['employee_dept_not_common_holiday'].push d.to_date  unless employee_dept_holiday_event.nil?
            end
          end
        end
      end

      if e.is_common ==false and e.is_holiday==false and e.is_exam ==true and e.is_published_exam == true # not_common_exam_event
        unless e.origin.nil?
          if @user.student?
            subject=e.origin.subject
            if subject.elective_group_id == nil
              p "nor#{e.id}"
              build_student_events_hash(e,'student_batch_exam',@user.student_record.batch_id,@show_month)
            else
              p "elec#{e.id}"
              build_student_events_hash(e,'student_batch_exam',@user.student_record.batch_id,@show_month)  if (@user.student_record.students_subjects.map{|sub| sub.subject_id}.include?(subject.id))
            end
          end
          if @user.parent?
            subject=e.origin.subject
            if subject.elective_group_id == nil
              build_student_events_hash(e,'student_batch_exam',@user.parent_record.batch_id,@show_month)
            else
              build_student_events_hash(e,'student_batch_exam',@user.parent_record.batch_id,@show_month)  if (@user.parent_record.students_subjects.map{|sub| sub.subject_id}.include?(subject.id))
            end
          end
          if @user.employee? and !privilege.include?("EventManagement")
            build_common_events_hash(e,'student_batch_exam',@show_month)
          end
          if @user.admin? or privilege.include?("EventManagement")
            student_batch_exam_event = e.batch_events
            if  e.start_date.to_date == e.end_date.to_date
              @notifications['student_batch_exam'] << e.start_date.to_date  unless student_batch_exam_event.nil?
            else
              (e.start_date.to_date..e.end_date.to_date).each do |d|
                @notifications['student_batch_exam'] << d.to_date unless student_batch_exam_event.nil?
              end
            end
          end
        end
      end

      if e.is_common ==false and e.is_holiday==false and e.is_due==false and e.is_exam ==false and (@user.admin? or privilege.include?("EventManagement"))  # not_common_exam_due_event
        
        build_common_events_hash(e,'employee_dept_not_common',@show_month)
        
      end
    end
    if @user.student? or @user.parent?
      @events = @notifications['common_events'] + @notifications['student_batch_not_common']
      @holiday_event =  @notifications['common_holidays']+ @notifications['student_batch_not_common_holiday']
    elsif @user.employee? and !privilege.include?("EventManagement")
      @events = @notifications['common_events'] + @notifications['employee_dept_not_common']
      @holiday_event =  @notifications['common_holidays']+ @notifications['employee_dept_not_common_holiday']
    elsif @user.admin? or privilege.include?("EventManagement")
      @events = @notifications['common_events'] + @notifications['employee_dept_not_common']
      @holiday_event =  @notifications['common_holidays']+ @notifications['employee_dept_not_common_holiday']
    end
  end


end