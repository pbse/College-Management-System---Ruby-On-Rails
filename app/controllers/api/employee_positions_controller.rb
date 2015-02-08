class Api::EmployeePositionsController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @employee_positions = EmployeePosition.active.search(params[:search])

    respond_to do |format|
      format.xml  { render :employee_positions }
    end
  end

end
