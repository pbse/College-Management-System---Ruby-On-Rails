class Api::EventsController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @user = User.find_by_username(params[:username])
    @events = @user.student? ? BatchEvent.find_all_by_batch_id(@user.try(:student_record).try(:batch_id)).map(&:event) : EmployeeDepartmentEvent.find_all_by_employee_department_id(@user.try(:employee_record.try(:employee_department_id))).map(&:event)
    @events = @events.select{|event| event.start_date == params[:start_date].to_date}
    respond_to do |format|
      unless (params[:username].present? and params[:start_date].present?)
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :events }
      end
    end
  end
end
