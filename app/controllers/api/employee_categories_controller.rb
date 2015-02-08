class Api::EmployeeCategoriesController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @employee_categories = EmployeeCategory.active.search(params[:search])

    respond_to do |format|
      format.xml  { render :employee_categories }
    end
  end

end
