class ClassTimingSetsController < ApplicationController
  before_filter :login_required
  before_filter :check_status
  before_filter :default_time_zone_present_time
  filter_access_to :all

  def index
    @class_timing_sets = ClassTimingSet.paginate(:group => 'class_timing_sets.id',:joins => "LEFT OUTER JOIN class_timings on class_timing_sets.id = class_timings.class_timing_set_id LEFT OUTER JOIN timetable_entries on class_timings.id = timetable_entries.class_timing_id",:select => "class_timing_sets.*,(count(timetable_entries.id)>0) as total_entries", :order => "class_timing_sets.name ASC", :page => params[:page], :per_page => 30)
    respond_to do |format|
      format.html #index.html.erb
    end
  end

  def new
    @class_timing_set = ClassTimingSet.new

    respond_to do |format|
      format.html #new.html.erb
    end
  end

  def create
    @class_timing_set = ClassTimingSet.new(params[:class_timing_set])

    if @class_timing_set.save
      flash[:notice] = t('class_timing_set_created')
      redirect_to class_timing_sets_path
    else
      render :new
    end
  end

  def edit
    @class_timing_set = ClassTimingSet.find(params[:id])

    respond_to do |format|
      format.html #edit.html.erb
    end
  end

  def update
    @class_timing_set = ClassTimingSet.find(params[:id])

    if @class_timing_set.update_attributes(params[:class_timing_set])
      flash[:notice] = t('class_timing_set_updated')
      redirect_to class_timing_sets_path
    else
      render :edit
    end
  end

  def show
    @class_timing_set = ClassTimingSet.find(params[:id])
    @class_timings = @class_timing_set.class_timings.active.paginate(:group => "class_timings.id", :joins => "LEFT OUTER JOIN timetable_entries on class_timings.id = timetable_entries.class_timing_id", :select => "class_timings.*,(count(timetable_entries.id)>0) as total_entries",:order => "class_timings.name ASC",:page => params[:page], :per_page => 30)

    respond_to do |format|
      format.html #show.html.erb
    end
  end

  def destroy
    @class_timing_set = ClassTimingSet.find(params[:id])
    @class_timing_set.destroy

    flash[:notice] = t('class_timing_set_deleted')
    redirect_to class_timing_sets_path
  end

  def new_class_timings
    @class_timing_set = ClassTimingSet.find(params[:id])
    @class_timing = @class_timing_set.class_timings.build

    respond_to do |format|
      format.js { render :action => 'new_class_timings' }
    end
  end

  def create_class_timings
    @class_timing = ClassTiming.new(params[:class_timing])
    @class_timing_set = ClassTimingSet.find(params[:class_timing][:class_timing_set_id])
    respond_to do |format|
      if @class_timing.save
        @class_timings = @class_timing_set.class_timings.active.paginate(:group => "class_timings.id", :joins => "LEFT OUTER JOIN timetable_entries on class_timings.id = timetable_entries.class_timing_id", :select => "class_timings.*,(count(timetable_entries.id)>0) as total_entries",:order => "class_timings.name ASC",:page => params[:page], :per_page => 30)
        format.html { redirect_to @class_timing_set }
        format.js { render :action => 'create_class_timings' }
      else
        @error = true
        format.html { render :action => "new_class_timings" }
        format.js { render :action => 'create_class_timings' }
      end
    end
  end

  def edit_class_timings
    @class_timing = ClassTiming.find(params[:id])
    @class_timing_set = ClassTimingSet.find(params[:class_timing_set_id])

    respond_to do |format|
      format.js { render :action => 'edit_class_timings' }
    end
  end

  def update_class_timings
    @class_timing = ClassTiming.find(params[:id])
    @class_timing_set = ClassTimingSet.find(params[:class_timing][:class_timing_set_id])

    respond_to do |format|
      if @class_timing.update_attributes(params[:class_timing])
        @class_timings = @class_timing_set.class_timings.active.paginate(:group => "class_timings.id", :joins => "LEFT OUTER JOIN timetable_entries on class_timings.id = timetable_entries.class_timing_id", :select => "class_timings.*,(count(timetable_entries.id)>0) as total_entries",:order => "class_timings.name ASC",:page => params[:page], :per_page => 30)
        format.html{ redirect_to @class_timing_set}
        format.js { render :action => "update_class_timings"}
      else
        @error = true
        format.html{ render :action => "edit_class_timings" }
        format.js { render :action => "update_class_timings"}
      end
    end
  end

  def delete_class_timings
    @class_timing = ClassTiming.find(params[:id])
    @class_timing_set = ClassTimingSet.find(params[:class_timing_set_id])
    @class_timing.destroy
    @class_timings = @class_timing_set.class_timings.active.paginate(:group => "class_timings.id", :joins => "LEFT OUTER JOIN timetable_entries on class_timings.id = timetable_entries.class_timing_id", :select => "class_timings.*,(count(timetable_entries.id)>0) as total_entries",:order => "class_timings.name ASC",:page => params[:page], :per_page => 30)
    render :update do |page|
      page.replace_html 'flash_box', :text => "<p class='flash-msg'> #{t('class_timing_deleted')} </p>"
      page.replace_html 'class_timings', :partial => 'class_timings'
    end
  end

  def new_batch_class_timing_set
    @batches = Batch.active
    @class_timing_sets = ClassTimingSet.find(:all, :order => "name ASC")
    @class_timing_set = ClassTimingSet.first

    if @class_timing_sets.empty?
      flash[:notice] = t('please_create')
      redirect_to class_timing_sets_path
    end
  end

  def list_batches
    @class_timing_set = ClassTimingSet.find_by_id(params[:class_timing_set_id])
    @assigned_batches = @class_timing_set.batches.active
    @all_batches = Batch.active.reject{|batch| @class_timing_set.batches.active.include? batch}

    render :update do |page|
      if @class_timing_set.present?
        page.replace_html 'list_batches', :partial => 'batch_section'
      else
        page.replace_html 'list_batches', :text => ''
      end
    end
  end

  def add_batch
    @class_timing_set = ClassTimingSet.find(params[:class_timing_set_id])
    @batches = Batch.active.find_all_by_id(params[:add_batch_ids].split(',')).compact
    @batches.each do |batch|
      batch.update_attributes(:class_timing_set_id => @class_timing_set.try(:id))
      current_timetables = Timetable.find(:all,:conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?) OR (timetables.start_date >= ? AND timetables.end_date >= ?)",@local_tzone_time.to_date,@local_tzone_time.to_date,@local_tzone_time.to_date,@local_tzone_time.to_date])
      current_timetables.each do |current_timetable|
        time_table_class_timing = TimeTableClassTiming.find_by_batch_id_and_timetable_id(batch.id,current_timetable.try(:id))
        if (time_table_class_timing.nil? and current_timetable.present?)
          TimeTableClassTiming.create(:batch_id => batch.id, :timetable_id => current_timetable.try(:id), :class_timing_set_id => batch.class_timing_set_id)
        elsif(time_table_class_timing.present? and time_table_class_timing.class_timing_set_id.nil? and current_timetable.present?)
          time_table_class_timing.update_attributes(:class_timing_set_id => batch.class_timing_set_id)
        end
      end
    end
    @assigned_batches = @class_timing_set.batches.active
    @all_batches = Batch.active.reject{|batch| @class_timing_set.batches.active.include? batch}
    render :update do |page|
      page.replace_html 'list_batches', :partial => 'batch_section'
    end
  end

  def remove_batch
    @class_timing_set = ClassTimingSet.find(params[:class_timing_set_id])
    @batches = Batch.active.find_all_by_id(params[:remove_batch_ids].split(',')).compact
    @batches.each do |batch|
      batch.update_attributes(:class_timing_set_id => nil)
    end
    @assigned_batches = @class_timing_set.batches.active
    @all_batches = Batch.active.reject{|batch| @class_timing_set.batches.active.include? batch}

    render :update do |page|
      page.replace_html 'list_batches', :partial => 'batch_section'
    end
  end
end
