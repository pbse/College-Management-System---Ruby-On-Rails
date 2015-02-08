class Api::AttendancesController < ApiController
  filter_access_to :all
  
  def index
    @xml = Builder::XmlMarkup.new
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @attendances = Attendance.search(params[:search]).all
    else
      @attendances = SubjectLeave.search(params[:search]).all
    end
    respond_to do |format|
      unless params[:search].present?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :attendances }
      end
    end

  end

  def new
    @xml = Builder::XmlMarkup.new
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @student = Student.find_by_admission_no(params[:admission_no])
      @month_date = params[:date]
      @attendance = Attendance.new
      @attendance.month_date = @month_date
    else
      @student = Student.find_by_admission_no(params[:admission_no])
      @attendance = SubjectLeave.new
    end
    
    respond_to do |format|
      format.xml  { render :xml => @attendance }
    end
  end

  def create
    @xml = Builder::XmlMarkup.new
    @student = Student.find_by_admission_no(params[:admission_no])
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=="SubjectWise"
      subject = Subject.find_by_batch_id_and_code(@student.try(:batch_id),params[:subject_code]).try(:id)
      class_timing = ClassTiming.find_by_batch_id_and_name(@student.try(:batch_id),params[:class_timing_name]).try(:id)
      class_timing ||= ClassTiming.find_by_batch_id_and_name(nil,params[:class_timing_name]).try(:id)
      timetable_entry = @student.nil? ? nil : Timetable.tte_for_the_day(@student.try(:batch),params[:date]).find_by_class_timing_id_and_subject_id(class_timing,subject)
      @attendance = SubjectLeave.new
      @attendance.subject_id = subject
      @attendance.employee_id = timetable_entry.nil? ? nil : timetable_entry.try(:employee_id)
      @attendance.class_timing_id = class_timing
    else
      @attendance = Attendance.new
      @attendance.forenoon = params[:forenoon]
      @attendance.afternoon = params[:afternoon]
    end
    @attendance.student_id = @student.try(:id)
    @attendance.batch_id = @student.try(:batch_id)
    @attendance.month_date = params[:date]
    @attendance.reason = params[:reason]
    respond_to do |format|
      if @attendance.save
        flash[:notice] = 'Attendance was successfully created.'
        format.xml  { render :attendance, :status => :created }
      else
        format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @xml = Builder::XmlMarkup.new
    student = Student.find_by_admission_no(params[:id])
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @attendance = Attendance.find_by_student_id_and_batch_id_and_month_date(student.try(:id),student.try(:batch_id),params[:date])
    else
      subject = Subject.find_by_batch_id_and_code(student.try(:batch_id),params[:subject_code]).try(:id)
      class_timing = ClassTiming.find_by_batch_id_and_name(student.try(:batch_id),params[:class_timing_name]).try(:id)
      #timetable_entry = Timetable.tte_for_the_day(Batch.first,params[:date]).find_by_class_timing_id_and_subject_id(class_timing,subject)
      @attendance = SubjectLeave.find_by_student_id_and_subject_id_and_month_date_and_batch_id_and_class_timing_id(student.try(:id),subject,params[:date],student.try(:batch_id),class_timing)
    end
    respond_to do |format|
      format.xml  { render :attendance }
    end
  end

  def update
    @xml = Builder::XmlMarkup.new
    student = Student.find_by_admission_no(params[:id])
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @attendance = Attendance.find_by_student_id_and_batch_id_and_month_date(student.try(:id),student.try(:batch_id),params[:date])
    else
      subject = Subject.find_by_batch_id_and_code(student.try(:batch_id),params[:subject_code]).try(:id)
      class_timing = ClassTiming.find_by_batch_id_and_name(student.try(:batch_id),params[:class_timing_name]).try(:id)
      class_timing ||= ClassTiming.find_by_batch_id_and_name(nil,params[:class_timing_name]).try(:id)
      #timetable_entry = Timetable.tte_for_the_day(Batch.first,params[:date]).find_by_class_timing_id_and_subject_id(class_timing,subject)
      @attendance = SubjectLeave.find_by_student_id_and_subject_id_and_month_date_and_batch_id_and_class_timing_id(student.try(:id),subject,params[:date],student.try(:batch_id),class_timing)
    end

    respond_to do |format|
      if @config.config_value=='Daily'
        @attendance.forenoon = params[:forenoon]
        @attendance.afternoon = params[:afternoon]
      end
      if @attendance.update_attributes(:reason => params[:reason])
        flash[:notice] = 'Post was successfully updated.'
        format.xml  { render :attendance }
      else
        format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @xml = Builder::XmlMarkup.new
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      student = Student.find_by_admission_no(params[:id])
      @attendance = Attendance.find_by_student_id_and_batch_id_and_month_date(student.try(:id),student.try(:batch_id),params[:date])
    else
      subject = Subject.find_by_batch_id_and_code(student.try(:batch_id),params[:subject_code]).try(:id)
      class_timing = ClassTiming.find_by_batch_id_and_name(student.try(:batch_id),params[:class_timing_name]).try(:id)
      #timetable_entry = Timetable.tte_for_the_day(Batch.first,params[:date]).find_by_class_timing_id_and_subject_id(class_timing,subject)
      @attendance = SubjectLeave.find_by_student_id_and_subject_id_and_month_date_and_batch_id_and_class_timing_id(student.try(:id),subject,params[:date],student.try(:batch_id),class_timing)
    end

    respond_to do |format|
      format.xml  { render :attendance }
    end
  end

  def destroy
    @xml = Builder::XmlMarkup.new
    student = Student.find_by_admission_no(params[:id])
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @attendance = Attendance.find_by_student_id_and_batch_id_and_month_date(student.try(:id),student.try(:batch_id),params[:date])
    else
      subject = Subject.find_by_batch_id_and_code(student.try(:batch_id),params[:subject_code]).try(:id)
      class_timing = ClassTiming.find_by_batch_id_and_name(student.try(:batch_id),params[:class_timing_name]).try(:id)
      class_timing = ClassTiming.find_by_batch_id_and_name(nil,params[:class_timing_name]).try(:id)
      #timetable_entry = Timetable.tte_for_the_day(Batch.first,params[:date]).find_by_class_timing_id_and_subject_id(class_timing,subject)
      @attendance = SubjectLeave.find_by_student_id_and_subject_id_and_month_date_and_batch_id_and_class_timing_id(student.try(:id),subject,params[:date],student.try(:batch_id),class_timing)
    end
    @attendance.destroy

    respond_to do |format|
      format.xml  { render :delete }
    end
  end
end
