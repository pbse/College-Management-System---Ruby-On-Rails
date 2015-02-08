class Api::EmployeeAttendancesController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @employee_attendances = EmployeeAttendance.search(params[:search]).all
    
    respond_to do |format|
      format.xml  { render :attendances }
    end

  end

  def create
    @xml = Builder::XmlMarkup.new
    @employee = Employee.find_by_employee_number(params[:employee_number])
    @leave_type = EmployeeLeaveType.find_by_code(params[:leave_type_code])
    @attendance = EmployeeAttendance.new
    @attendance.employee_id = @employee.try(:id)
    @attendance.employee_leave_type_id = @leave_type.try(:id)
    @attendance.attendance_date = params[:date]
    @attendance.reason = params[:reason]
    @attendance.is_half_day = params[:is_half_day]
    
    respond_to do |format|
      @reset_count = EmployeeLeave.find_by_employee_id(@attendance.employee_id, :conditions=> "employee_leave_type_id = '#{@attendance.employee_leave_type_id}'")
      if @attendance.save
        leaves_taken = @reset_count.leave_taken
        if @attendance.is_half_day
          leave = leaves_taken.to_f+(0.5)
          @reset_count.update_attributes(:leave_taken => leave)
        else
          leave = leaves_taken.to_f+(1)
          @reset_count.update_attributes(:leave_taken => leave)
        end
        flash[:notice] = 'Attendance was successfully created.'
        format.xml  { render :attendance, :status => :created }
      else
        format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @xml = Builder::XmlMarkup.new
    @employee = Employee.find_by_employee_number(params[:id])
    @leave_type = EmployeeLeaveType.find_by_code(params[:leave_type_code])
    @attendance = EmployeeAttendance.find_by_employee_id_and_attendance_date(@employee.try(:id),params[:date])
  
    respond_to do |format|
      if @attendance.update_attributes(:employee_leave_type_id => @leave_type.try(:id),:is_half_day => params[:is_half_day],:reason => params[:reason])
        format.xml  { render :attendance }
      else
        format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @xml = Builder::XmlMarkup.new
    @employee = Employee.find_by_employee_number(params[:id])
    @attendance = EmployeeAttendance.find_by_employee_id_and_attendance_date(@employee.try(:id),params[:date])
    @attendance.destroy

    respond_to do |format|
      format.xml  { render :delete }
    end
  end

end
