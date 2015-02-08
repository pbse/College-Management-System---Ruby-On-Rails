class Api::TimetablesController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @user = User.find_by_username(params[:username])
    @timetable = Timetable.search(params[:search]).first
    if @user.student?
      @timetable_entries = TimetableEntry.search(:batch_name_equals => @user.student_record.batch.try(:name),:batch_course_code_equals => @user.student_record.batch.try(:code),:timetable_id_equals => @timetable.try(:id)).all
    elsif @user.employee?
      @timetable_entries = TimetableEntry.search(:employee_id_equals => @user.employee_record.try(:id),:timetable_id_equals => @timetable.try(:id)).all
    end

    respond_to do |format|
      format.xml { render :timetable_entries}
    end
  end

  private

end
