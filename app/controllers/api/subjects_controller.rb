class Api::SubjectsController < ApiController
  filter_access_to :all
  
  def index
    @xml = Builder::XmlMarkup.new
    @subjects = Subject.search(params[:search]).all(:conditions => {:is_deleted => false})

    respond_to do |format|
      unless params[:search].present? and params[:search][:batch_name_equals].present? and params[:search][:batch_course_code_equals].present?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :subjects }
      end
    end
  end

  def show
    @xml = Builder::XmlMarkup.new
    @user = User.find_by_username(params[:id])
    if @user.student?
      @student = @user.student_record
      @subjects = @student.batch.subjects.all(:conditions => {:is_deleted => false})
    elsif @user.employee?
      @employee = @user.employee_record
      @subjects = @employee.subjects
    end

    respond_to do |format|
      unless @user.nil?
        format.xml  { render :subjects }
      else
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      end
    end
  end
end
