class Api::PayrollCategoriesController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @payroll_categories = PayrollCategory.active

    respond_to do |format|
      format.xml { render :payroll_categories }
    end
  end

  def show
    @xml = Builder::XmlMarkup.new
    @employee = Employee.find_by_employee_number(params[:id])
    @employee_salary_structures = EmployeeSalaryStructure.find_all_by_employee_id(@employee.try(:id), :order=>"payroll_category_id ASC")

    respond_to do |format|
      format.xml { render :employee_salary_structure }
    end
  end
end
