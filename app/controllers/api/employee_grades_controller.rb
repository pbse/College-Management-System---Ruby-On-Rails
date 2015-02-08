class Api::EmployeeGradesController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @employee_grades = EmployeeGrade.active.search(params[:search])

    respond_to do |format|
      format.xml  { render :employee_grades }
    end
  end

end
