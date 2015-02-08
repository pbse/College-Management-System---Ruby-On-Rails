#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
#require 'fedena_setting.rb'
class ApplicationController < ActionController::Base
  helper :all
  helper_method :can_access_request?
  helper_method :can_access_plugin?
  helper_method :can_access_feature?
  helper_method :currency
  protect_from_forgery # :secret => '434571160a81b5595319c859d32060c1'
  filter_parameter_logging :password
  
  before_filter { |c| Authorization.current_user = c.current_user }
  before_filter :message_user
  before_filter :set_user_language
  before_filter :set_variables
  before_filter :login_check
  before_filter :set_host

  before_filter :dev_mode
  include CustomInPlaceEditing

  def check_status
    unless Configuration.find_by_config_key("SetupAttendance").try(:config_value) == "1"
      flash[:notice] = "System under maintainance. Try the feature after some time."
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def login_check
    if session[:user_id].present?
      unless (controller_name == "user") and ["first_login_change_password","login","logout","forgot_password"].include? action_name
        user = User.active.find(session[:user_id])
        setting = Configuration.get_config_value('FirstTimeLoginEnable')
        if setting == "1" and user.is_first_login != false
          flash[:notice] = "#{t('first_login_attempt')}"
          redirect_to :controller => "user",:action => "first_login_change_password"
        end
      end
    end
  end


  def dev_mode
    if Rails.env == "development"

    end
  end

  def set_variables
    unless @current_user.nil?
      @attendance_type = Configuration.get_config_value('StudentAttendanceType') unless @current_user.student?
      @modules = Configuration.available_modules
    end
  end


  def set_language
    session[:language] = params[:language]
    @current_user.clear_menu_cache
    render :update do |page|
      page.reload
    end
  end


  if Rails.env.production?
    rescue_from ActiveRecord::RecordNotFound do |exception|
      flash[:notice] = "#{t('flash_msg2')} , #{exception} ."
      logger.info "[FedenaRescue] AR-Record_Not_Found #{exception.to_s}"
      log_error exception
      redirect_to :controller=>:user ,:action=>:dashboard
    end

    rescue_from NoMethodError do |exception|
      flash[:notice] = "#{t('flash_msg3')}"
      logger.info "[FedenaRescue] No method error #{exception.to_s}"
      log_error exception
      redirect_to :controller=>:user ,:action=>:dashboard
    end

    rescue_from ActionController::InvalidAuthenticityToken do|exception|
      flash[:notice] = "#{t('flash_msg43')}"
      logger.info "[FedenaRescue] Invalid Authenticity Token #{exception.to_s}"
      log_error exception
      if request.xhr?
        render(:update) do|page|
          page.redirect_to :controller => 'user', :action => 'dashboard'
        end
      else
        redirect_to :controller => 'user', :action => 'dashboard'
      end
    end

    rescue_from ActionController::MethodNotAllowed do |exception|
      logger.info "[FedenaRescue] Method Not Allowed #{exception.to_s}"
      log_error exception
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
        format.xml  { head :not_found }
        format.any  { head :not_found }
      end
    end
  end

 
  def only_assigned_employee_allowed
    @privilege = @current_user.privileges.map{|p| p.name}
    if @current_user.employee?
      @employee_subjects= @current_user.employee_record.subjects
      if @employee_subjects.empty? and !@privilege.include?("StudentAttendanceView") and !@privilege.include?("StudentAttendanceRegister")
        flash[:notice] = "#{t('flash_msg4')}"
        redirect_to :controller => 'user', :action => 'dashboard'
      else
        @allow_access = true
      end
    end
  end

  def restrict_employees_from_exam
    if @current_user.employee?
      @employee_subjects= @current_user.employee_record.subjects
      if @employee_subjects.empty? and !(Batch.active.collect(&:employee_id).include?(@current_user.employee_record.id.to_s)) and !@current_user.privileges.map{|p| p.name}.include?("ExaminationControl") and !@current_user.privileges.map{|p| p.name}.include?("EnterResults") and !@current_user.privileges.map{|p| p.name}.include?("ViewResults")
        flash[:notice] = "#{t('flash_msg4')}"
        redirect_to :controller => 'user', :action => 'dashboard'
      else
        @allow_for_exams = true
      end
    end
  end

  def block_unauthorised_entry
    if @current_user.employee?
      @employee_subjects= @current_user.employee_record.subjects
      if @employee_subjects.empty? and !@current_user.privileges.map{|p| p.name}.include?("ExaminationControl")
        flash[:notice] = "#{t('flash_msg4')}"
        redirect_to :controller => 'user', :action => 'dashboard'
      else
        @allow_for_exams = true
      end
    end
  end
  
  def initialize
    @title = FedenaSetting.company_details[:company_name]
  end

  def message_user
    @current_user = current_user
    logger.info("Username : #{@current_user.username} Role : #{@current_user.role_name}") if @current_user.present?
  end

  def current_user
    User.active.find(session[:user_id]) unless session[:user_id].nil?
  end

  
  def find_finance_managers
    Privilege.find_by_name('FinanceControl').users
  end

  def permission_denied
    flash[:notice] = "#{t('flash_msg4')}"
    redirect_to :controller => 'user', :action => 'dashboard'
  end

  def date_format_check
    begin
      @start_date= Date.parse(params[:start_date]) if params[:start_date]
      @end_date= Date.parse(params[:end_date]) if params[:end_date]
    rescue ArgumentError
    end

    if (@start_date.nil? or @end_date.nil?)
      flash[:notice]=t('invalid_date_format')
      redirect_to :controller => "user", :action => "dashboard"
      return false
    end
    return true
  end
  
  protected

  def set_precision
    precision_count = Configuration.get_config_value('PrecisionCount')
    @precision = precision_count.to_i < 2 ? 2 : precision_count.to_i > 9 ? 8 : precision_count
  end

  def set_host
    Fedena.present_user=current_user
    Fedena.present_student_id=session[:student_id]
    Fedena.hostname="#{request.protocol}#{request.host_with_port}"
    Fedena.rtl=RTL_LANGUAGES.include? I18n.locale.to_sym
  end
  def login_required
    unless session[:user_id]
      session[:back_url] = request.url
      redirect_to '/'
    end
  end

  def check_if_loggedin
    if session[:user_id]
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def configuration_settings_for_hr
    hr = Configuration.find_by_config_value("HR")
    if hr.nil?
      redirect_to :controller => 'user', :action => 'dashboard'
      flash[:notice] = "#{t('flash_msg4')}"
    end
  end

  

  def configuration_settings_for_finance
    finance = Configuration.find_by_config_value("Finance")
    if finance.nil?
      redirect_to :controller => 'user', :action => 'dashboard'
      flash[:notice] = "#{t('flash_msg4')}"
    end
  end

  def only_admin_allowed
    redirect_to :controller => 'user', :action => 'dashboard' unless current_user.admin?
  end

  def protect_other_student_data
    if current_user.student? or current_user.parent?
      student = current_user.student_record if current_user.student?
      student = current_user.parent_record if current_user.parent?
      #      render :text =>student.id and return
      params[:id].nil?? student_id=session[:student_id]: student_id=params[:id]
      unless params[:id].to_i == student.id or params[:student].to_i == student.id or params[:student_id].to_i == student.id or student.siblings.select{|s| s.immediate_contact_id==current_user.guardian_entry.id}.collect(&:id).include?student_id.to_i
       
        flash[:notice] = "#{t('flash_msg5')}"
        redirect_to :controller=>"user", :action=>"dashboard"
      end
    end
  end

  def protect_user_data
    unless current_user.admin?
      unless params[:id].to_s == current_user.username
        flash[:notice] = "#{t('flash_msg5')}"
        redirect_to :controller=>"user", :action=>"dashboard"
      end
    end
  end
  
  def limit_employee_profile_access
    unless @current_user.employee
      unless params[:id] == @current_user.employee_record.id
        priv = @current_user.privileges.map{|p| p.name}
        unless current_user.admin? or priv.include?("HrBasics") or priv.include?("EmployeeSearch")
          flash[:notice] = "#{t('flash_msg5')}"
          redirect_to :controller=>"user", :action=>"dashboard"
        end
      end
    end
  end

  def protect_other_employee_data
    if current_user.employee?
      employee = current_user.employee_record
      #    pri = Privilege.find(:all,:select => "privilege_id",:conditions=> 'privileges_users.user_id = ' + current_user.id.to_s, :joins =>'INNER JOIN `privileges_users` ON `privileges`.id = `privileges_users`.privilege_id' )
      #    privilege =[]
      #    pri.each do |p|
      #      privilege.push p.privilege_id
      #    end
      #    unless privilege.include?('9') or privilege.include?('14') or privilege.include?('17') or privilege.include?('18') or privilege.include?('19')
      unless params[:id].to_i == employee.id or current_user.role_symbols.include? "payslip_powers".to_sym
        flash[:notice] = "#{t('flash_msg5')}"
        redirect_to :controller=>"user", :action=>"dashboard"
      end
    end
  end

  def protect_leave_history
    if current_user.employee?
      employee = Employee.find(params[:id])
      employee_user = employee.user
      unless employee_user.id == current_user.id
        unless current_user.role_symbols.include?(:hr_basics) or current_user.role_symbols.include?(:employee_attendance)
          flash[:notice] = "#{t('flash_msg6')}"
          redirect_to :controller=>"user", :action=>"dashboard"
        end
      end
    end
  end
  #  end

  #reminder filters
  def protect_view_reminders
    reminder = Reminder.find(params[:id2])
    unless reminder.recipient == current_user.id
      flash[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller=>"reminder", :action=>"index"
    end
  end

  def protect_sent_reminders
    reminder = Reminder.find(params[:id2])
    unless reminder.sender == current_user.id
      flash[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller=>"reminder", :action=>"index"
    end
  end

  #employee_leaves_filters
  def protect_leave_dashboard
    employee = Employee.find(params[:id])
    employee_user = employee.user
    #    unless permitted_to? :employee_attendance_pdf, :employee_attendance
    unless employee_user.id == current_user.id
      flash[:notice] = "#{t('flash_msg6')}"
      redirect_to :controller=>"user", :action=>"dashboard"
      #    end
    end
  end

  def protect_applied_leave
    applied_leave = ApplyLeave.find(params[:id])
    applied_employee = applied_leave.employee
    applied_employee_user = applied_employee.user
    unless applied_employee_user.id == current_user.id
      flash[:notice]="#{t('flash_msg5')}"
      redirect_to :controller=>"user", :action=>"dashboard"
    end
  end

  def protect_manager_leave_application_view
    applied_leave = ApplyLeave.find(params[:id])
    applied_employee = applied_leave.employee
    applied_employees_manager = Employee.find_by_user_id(applied_employee.reporting_manager_id)
    applied_employees_manager_user = applied_employees_manager.user
    unless applied_employees_manager_user.id == current_user.id or current_user.admin? or current_user.privileges.map(&:name).include? 'HrBasics' or current_user.privileges.map(&:name).include? 'EmployeeAttendance'
      flash[:notice]="#{t('flash_msg5')}"
      redirect_to :controller=>"user", :action=>"dashboard"
    end
  end

  def render(options = nil, extra_options = {}, &block)
    if RTL_LANGUAGES.include? I18n.locale.to_sym
      unless options.nil?
        unless request.xhr?
          if options.class == Hash
            if options[:pdf]
              options ||= {}
              options = options.merge(:zoom => 0.68) if options[:zoom].blank?
            end
          end
        end
      end
    end
    super(options, extra_options, &block)
  end

  def default_time_zone_present_time
    server_time = Time.now
    server_time_to_gmt = server_time.getgm
    @local_tzone_time = server_time
    time_zone = Configuration.find_by_config_key("TimeZone")
    unless time_zone.nil?
      unless time_zone.config_value.nil?
        zone = TimeZone.find(time_zone.config_value)
        if zone.difference_type=="+"
          @local_tzone_time = server_time_to_gmt + zone.time_difference
        else
          @local_tzone_time = server_time_to_gmt - zone.time_difference
        end
      end
    end
    return @local_tzone_time
  end

  #  def can_access_request? (action,controller)
  #    permitted_to?(action,controller)
  #  end

  def can_access_request? (privilege, object_or_sym = nil, options = {}, &block)
    permitted_to?(privilege, object_or_sym, options, &block)
  end

  def can_access_plugin?(plugin)
    FedenaPlugin.can_access_plugin?(plugin)
  end

  def can_access_feature?(feature)
    if Feature.find_by_feature_key(feature).try(:is_enabled)==false
      return false
    else
      return true
    end
  end

  def currency
    Configuration.currency 
  end

  private
  def set_user_language
    lan = Configuration.find_by_config_key("Locale")
    I18n.default_locale = :en
    Translator.fallback(true)
    if session[:language].nil?
      I18n.locale = lan.config_value
    else
      I18n.locale = session[:language]
    end
    News.new.reload_news_bar
  end
  def page_not_found
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end
end
