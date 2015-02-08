class Api::EmployeeDepartmentsController < ApiController
  filter_access_to :all
  
  def index
    @xml = Builder::XmlMarkup.new
    @employee_departments = EmployeeDepartment.active.search(params[:search])

    respond_to do |format|
      format.xml  { render :employee_departments }
    end
  end
end