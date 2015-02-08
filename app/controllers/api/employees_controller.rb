class Api::EmployeesController < ApiController
  filter_access_to :all
  
  def index
    @xml = Builder::XmlMarkup.new
    @employees = Employee.search(params[:search])

    respond_to do |format|
      unless params[:search].present?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :employees }
      end
    end
  end

  def show
    @xml = Builder::XmlMarkup.new
    @employee = Employee.find_by_employee_number(params[:id])
    @employees = @employee.try(:get_profile_data)
    respond_to do |format|
      unless @employee.nil?
        format.xml  { render :employee }
      else
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      end
    end
  end

  def leave_profile
    @xml = Builder::XmlMarkup.new
    search_params = params[:search] || Hash.new
    search_params = search_params.merge(:employee_employee_number_equals => current_user.username)
    @employee_attendances = EmployeeAttendance.search(params[:search]).all
    render :template => 'api/employee_attendances/attendances.xml'
  end

  def employee_structure
    @xml = Builder::XmlMarkup.new
    @additional_fields = AdditionalField.all(:conditions=>"status = true")
    @bank_fields = BankField.all(:conditions=>"status = true")
    
    respond_to do |format|
      format.xml  { render :employee_structure }
    end
  end

  def create
    @xml = Builder::XmlMarkup.new
    employee_params_main = nil
    begin
      employee_params_main = File.read(params[:employee].try(:path))
    rescue Exception => e
      render "single_access_tokens/500.xml", :status => :bad_request  and return
      puts e.message
    end
    employee_params = employee_params_main.present? ? Hash.from_xml(employee_params_main).inject({}){|memo,(k,v)| memo[k.to_s] = v; memo}["employee"].inject({}){|memo,(k,v)| memo[k.to_s] = v; memo} : Hash.new
    employee_params ||= Hash.new
    employee_additional_details_params = employee_params.delete("employee_additional_details")
    employee_additional_details_params ||= Hash.new
    employee_bank_details_params = employee_params.delete("employee_bank_details")
    employee_bank_details_params ||= Hash.new
    employee_params.keys.each do |key|
      if Employee.reflect_on_all_associations.map(&:name).include? key.to_sym
        query_model = Employee.reflect_on_association(key.to_sym).options[:class_name].nil? ? key : Employee.reflect_on_association(key.to_sym).options[:class_name]
        employee_params[key] = query_model.camelize.constantize.find_by_name(employee_params[key]) unless key == "reporting_manager"
        if key == "reporting_manager"
          reporting_manager = Employee.find_by_employee_number(employee_params[key]).try(:user)
          employee_params[key] = reporting_manager
        end
      end
    end
    @employee = Employee.new(employee_params)
    @employee.photo = params[:employee_photo]
    respond_to do |format|
      if employee_params_main.present?
        if employee_additional_details_params.present?
          additional_datas = employee_additional_details_params
          additional_datas["additional_field"].to_a.each do |additional_data|
            additional_field = AdditionalField.active.find_by_name(additional_data["name"])
            @employee.employee_additional_details.build(:additional_field_id => additional_field.try(:id),:additional_info => additional_data["value"]) if additional_field.present?
          end
        end

        if employee_bank_details_params.present?
          bank_datas = employee_bank_details_params
          bank_datas["bank_field"].to_a.each do |bank_data|
            bank_field = BankField.active.find_by_name(bank_data["name"])
            @employee.employee_bank_details.build(:bank_field_id => bank_field.try(:id),:bank_info => bank_data["value"]) if bank_field.present?
          end
        end
        if @employee.save
          @additional_data = Hash.new
          @bank_data = Hash.new
          @additional_fields = AdditionalField.all(:conditions=>"status = true")
          @additional_fields.each do |additional_field|
            detail = EmployeeAdditionalDetail.find_by_additional_field_id_and_employee_id(additional_field.id,@employee.id)
            @additional_data[additional_field.name] = detail.try(:additional_info)
          end
          @bank_fields = BankField.all(:conditions=>"status = true")
          @additional_fields.each do |bank_field|
            detail = EmployeeBankDetail.find_by_bank_field_id_and_employee_id(bank_field.id,@employee.id)
            @bank_data[bank_field.name] = detail.try(:bank_info)
          end
          exp_years = @employee.experience_year
          exp_months = @employee.experience_month
          date = Date.today
          total_current_exp_days = (date-@employee.joining_date).to_i
          current_years = (total_current_exp_days/365)
          rem = total_current_exp_days%365
          current_months = rem/30
          total_month = (exp_months || 0)+current_months
          year = total_month/12
          month = total_month%12
          @total_years = (exp_years || 0)+current_years+year
          @total_months = month
          @employees = @employee.get_profile_data
          format.xml  { render :employee, :status => :created }
        else
          format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
      end
    end
  end

  def upload_photo
    @employee = Employee.find_by_employee_number(params[:id])
    if @employee.nil?
      render "single_access_tokens/500.xml", :status => :bad_request  and return
    else
      @employee.photo = params[:photo]
      @employee.save
      respond_to do |format|
        format.xml {render :employee_photo,:status => :created}
      end
    end
  end

  def destroy
    @xml = Builder::XmlMarkup.new
    @employee = Employee.find_by_employee_number(params[:id])

    respond_to do |format|
      unless @employee.has_dependency
        employee_subject=EmployeesSubject.destroy_all(:employee_id => @employee.id)
        @employee.user.destroy
        @employee.destroy
        if @employee.destroy
          format.xml  { render :delete }
        else
          format.xml  { render :xml => @employee.errors }
        end
      else
        format.xml  { render :dependent }
      end
    end
  end
end
