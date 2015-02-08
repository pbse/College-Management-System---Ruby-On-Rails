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

class FinanceController < ApplicationController
  before_filter :login_required,:configuration_settings_for_finance
  before_filter :set_precision
  filter_access_to :all

  def index
    @hr = Configuration.find_by_config_value("HR")
  end

  def automatic_transactions
    @cat_names = ["'Fee'","'Salary'"]
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      @cat_names << "'#{category[:category_name]}'"
    end
    @triggers = FinanceTransactionTrigger.all
    @categories = FinanceTransactionCategory.find(:all ,:conditions => ["name NOT IN (#{@cat_names.join(',')}) and is_income=1 and deleted=0 "])
  end

  def donation
    @donation = FinanceDonation.new(params[:donation])
    if request.post? and @donation.save
      flash[:notice] = "#{t('flash1')}"
      redirect_to :action => 'donation_receipt', :id => @donation.id
    end
  end

  def donation_receipt
    @donation = FinanceDonation.find(params[:id])
  end

  def donation_edit
    @donation = FinanceDonation.find(params[:id])
    @transaction = FinanceTransaction.find(@donation.transaction_id)
    if request.post? and @donation.update_attributes(params[:donation])
      donor = "#{t('flash15')} #{params[:donation][:donor]}"
      FinanceTransaction.update(@transaction.id, :description => params[:donation][:description], :title=>donor, :amount=>params[:donation][:amount], :transaction_date=>@donation.transaction_date)
      redirect_to :action => 'donors'
      flash[:notice] = "#{t('flash16')}"
    end
  end

  def donation_delete
    @donation = FinanceDonation.find(params[:id])
    @transaction = FinanceTransaction.find(@donation.transaction_id)
    if  @donation.destroy
      @transaction.destroy
      redirect_to :action => 'donors'
      flash[:notice] = "#{t('flash25')}"
    end
  end

  def donation_receipt_pdf
    @donation = FinanceDonation.find(params[:id])
    @currency_type = currency
    render :pdf => 'donation_receipt_pdf'

  end

  def donors
    @donations = FinanceDonation.find(:all, :order => 'transaction_date desc')
  end

  def expense_create
    @finance_transaction = FinanceTransaction.new
    @categories = FinanceTransactionCategory.expense_categories
    if @categories.empty?
      flash[:notice] = "#{t('flash2')}"
    end
    if request.post?
      @finance_transaction = FinanceTransaction.new(params[:finance_transaction])
      if @finance_transaction.save
        flash[:notice] = "#{t('flash3')}"
        redirect_to :action=>"expense_create"
      else
        render :action=>"expense_create"
      end
    end
  end

  def expense_edit
    @transaction = FinanceTransaction.find(params[:id])
    @categories = FinanceTransactionCategory.all(:conditions =>"name != 'Salary' and is_income = false and deleted = false" )
    if request.post? and @transaction.update_attributes(params[:transaction])
      flash[:notice] = "#{t('flash4')}"
      redirect_to  :action=>:expense_list
    end
  end

  def expense_list
  end

  def expense_list_update
    if params[:start_date].to_date > params[:end_date].to_date
      flash[:warn_notice] = "#{t('flash17')}"
      redirect_to :action => 'expense_list'
    end
    @start_date = (params[:start_date]).to_date
    @end_date = (params[:end_date]).to_date
    @expenses = FinanceTransaction.expenses(@start_date,@end_date)
  end

  def expense_list_pdf
    if date_format_check
      @currency_type = currency
      @expenses = FinanceTransaction.expenses(@start_date,@end_date)
      render :pdf => 'expense_list_pdf'
    end
  end

  def income_create
    @finance_transaction = FinanceTransaction.new()
    @categories = FinanceTransactionCategory.income_categories
    if @categories.empty?
      flash[:notice] = "#{t('flash5')}"
    end
    if request.post?
      @finance_transaction = FinanceTransaction.new(params[:finance_transaction])
      if @finance_transaction.save
        flash[:notice] = "#{t('flash6')}"
        redirect_to :action=>"income_create"
      else
        render :action=>"income_create"
      end
    end
  end

  def monthly_income

  end

  def income_edit
    @cat_names = ["'Fee'","'Salary'","'Donation'"]
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      @cat_names << "'#{category[:category_name]}'"
    end
    @transaction = FinanceTransaction.find(params[:id])
    @categories = FinanceTransactionCategory.all(:conditions => "is_income=true and name NOT IN (#{@cat_names.join(',')}) and deleted = false")
    if request.post? and @transaction.update_attributes(params[:transaction])
      flash[:notice] = "#{t('flash7')}"
      redirect_to :action=> 'income_list'
    else
      render :income_edit
    end
  end

  def income_list
  end

  def delete_transaction
    @transaction = FinanceTransaction.find_by_id(params[:id])
    income = @transaction.category.is_income?
    if income
      auto_transactions = FinanceTransaction.find_all_by_master_transaction_id(params[:id])
      auto_transactions.each { |a| a.destroy } unless auto_transactions.nil?
    end
    @transaction.destroy
    flash[:notice]="#{t('flash18')}"
    if income
      redirect_to :action=>'income_list'
    else
      redirect_to :action=>'expense_list'
    end


  end

  def income_list_update
    @start_date = (params[:start_date]).to_date
    @end_date = (params[:end_date]).to_date
    @incomes = FinanceTransaction.incomes(@start_date,@end_date)
  end

  def income_details
    if date_format_check

      @income_category = FinanceTransactionCategory.find(params[:id])
      @incomes = @income_category.finance_transactions.find(:all,:conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])

    end
  end

  def income_list_pdf
    if date_format_check
      @currency_type = currency
      @incomes = FinanceTransaction.incomes(@start_date,@end_date)
      render :pdf => 'income_list_pdf', :zoom=>0.68#, :show_as_html=>true
    end
  end

  def income_details_pdf
    if date_format_check
      @income_category = FinanceTransactionCategory.find(params[:id])
      @incomes = @income_category.finance_transactions.find(:all,:conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])
      render :pdf => 'income_details_pdf'
    end
  end

  def categories
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false},:order=>'name asc')
    @fixed_categories = @categories.reject{|c|!c.is_fixed}
    @other_categories = @categories.reject{|c|c.is_fixed}
  end

  def category_new
    @finance_transaction_category = FinanceTransactionCategory.new
  end

  def category_create
    @finance_category = FinanceTransactionCategory.new(params[:finance_category])
    render :update do |page|
      if @finance_category.save
        @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false})
        @fixed_categories = @categories.reject{|c|!c.is_fixed}
        @other_categories = @categories.reject{|c|c.is_fixed}
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'category-list', :partial => 'category_list'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg35')}</p>"

      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_category
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def category_delete
    @finance_category = FinanceTransactionCategory.find(params[:id])
    @finance_category.update_attributes(:deleted => true)
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false})
    @fixed_categories = @categories.reject{|c|!c.is_fixed}
    @other_categories = @categories.reject{|c|c.is_fixed}
  end

  def category_edit
    @finance_category = FinanceTransactionCategory.find(params[:id])
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false})
  end

  def category_update
    @finance_category = FinanceTransactionCategory.find(params[:id])
    unless  @finance_category.update_attributes(params[:finance_category])
      @errors=true
    end
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false})
    @fixed_categories = @categories.reject{|c|!c.is_fixed}
    @other_categories = @categories.reject{|c|c.is_fixed}
  end

  def transaction_trigger_create
    @trigger = FinanceTransactionTrigger.new(params[:transaction_trigger])
    render :update do |page|
      if @trigger.save
        @triggers = FinanceTransactionTrigger.all
        page.replace_html 'transaction-triggers-list', :partial => 'transaction_triggers_list'
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg17')}</p>"

      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @trigger
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end




  def transaction_trigger_edit
    @cat_names = ["'Fee'","'Salary'"]
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      @cat_names << "'#{category[:category_name]}'"
    end
    @transaction_trigger = FinanceTransactionTrigger.find(params[:id])
    @categories = FinanceTransactionCategory.find(:all ,:conditions => ["name NOT IN (#{@cat_names.join(',')}) and is_income=1 and deleted=0 "])
  end

  def transaction_trigger_update
    @transaction_trigger = FinanceTransactionTrigger.find(params[:id])
    render :update do |page|
      if @transaction_trigger.update_attributes(params[:transaction_trigger])
        @triggers = FinanceTransactionTrigger.all
        page.replace_html 'transaction-triggers-list', :partial => 'transaction_triggers_list'
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg17')}</p>"

      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @transaction_trigger
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def transaction_trigger_delete
    @trigger = FinanceTransactionTrigger.find(params[:id])
    @trigger.destroy
    @triggers = FinanceTransactionTrigger.all
    render :update do |page|
      page.replace_html 'transaction-triggers-list', :partial => 'transaction_triggers_list'
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg19')}</p>"
    end
  end

  #transaction-----------------------


  def update_monthly_report

    fixed_category_name
    @hr = Configuration.find_by_config_value("HR")
    if date_format_check
      unless @start_date > @end_date
        @transactions = FinanceTransaction.find(:all, :order => 'transaction_date desc', :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])
        @other_transaction_categories = FinanceTransactionCategory.find(:all, :conditions => ["finance_transactions.transaction_date >= '#{@start_date}' and finance_transactions.transaction_date <= '#{@end_date}'and finance_transaction_categories.id NOT IN (#{@fixed_cat_ids.join(",")})"],:joins=>[:finance_transactions]).uniq
        @transactions_fees = FinanceTransaction.total_fees(@start_date,@end_date).map{|t| t.transaction_total.to_f}.sum
        @salary = FinanceTransaction.sum('amount',:conditions=>{:title=>"Monthly Salary",:transaction_date=>@start_date..@end_date}).to_f
        @donations_total = FinanceTransaction.donations_triggers(@start_date,@end_date)
        @grand_total = FinanceTransaction.grand_total(@start_date,@end_date)
        @category_transaction_totals = {}
        FedenaPlugin::FINANCE_CATEGORY.each do |category|
          @category_transaction_totals["#{category[:category_name]}"] =   FinanceTransaction.total_transaction_amount(category[:category_name],@start_date,@end_date)
        end
        @graph = open_flash_chart_object(960, 500, "graph_for_update_monthly_report?start_date=#{@start_date}&end_date=#{@end_date}")
      else
        flash[:warn_notice] = "#{t('flash17')}"
        redirect_to :action=>:monthly_report
      end
    end
  end


  def transaction_pdf
    fixed_category_name
    @hr = Configuration.find_by_config_value("HR")
    if date_format_check
      @transactions = FinanceTransaction.find(:all,
        :order => 'transaction_date desc', :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])
      @other_transaction_categories = FinanceTransactionCategory.find(:all, :conditions => ["finance_transactions.transaction_date >= '#{@start_date}' and finance_transactions.transaction_date <= '#{@end_date}'and finance_transaction_categories.id NOT IN (#{@fixed_cat_ids.join(",")})"],:joins=>[:finance_transactions]).uniq
      @transactions_fees = FinanceTransaction.total_fees(@start_date,@end_date).map{|t| t.transaction_total.to_f}.sum
      @salary = FinanceTransaction.sum('amount',:conditions=>{:title=>"Monthly Salary",:transaction_date=>@start_date..@end_date}).to_f
      @donations_total = FinanceTransaction.donations_triggers(@start_date,@end_date)
      @grand_total = FinanceTransaction.grand_total(@start_date,@end_date)
      @category_transaction_totals = {}
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        @category_transaction_totals["#{category[:category_name]}"] =   FinanceTransaction.total_transaction_amount(category[:category_name],@start_date,@end_date)
      end
      render :pdf => 'transaction_pdf'
    end
  end

  def salary_department
    if date_format_check
      archived_employee_salary=FinanceTransaction.all(:select=>"sum(finance_transactions.amount) as amount,employee_departments.id,employee_departments.name",:conditions=>{:title=>"Monthly Salary",:transaction_date=>@start_date..@end_date},:joins=>"INNER JOIN archived_employees on archived_employees.former_id= finance_transactions.payee_id INNER JOIN employee_departments on employee_departments.id= archived_employees.employee_department_id",:group=>"employee_departments.id",:order=>"employee_departments.name").group_by(&:id)
      employee_salary=FinanceTransaction.all(:select=>"sum(finance_transactions.amount) as amount,employee_departments.id,employee_departments.name",:conditions=>{:title=>"Monthly Salary",:transaction_date=>@start_date..@end_date},:joins=>"INNER JOIN employees on employees.id= finance_transactions.payee_id LEFT OUTER JOIN employee_departments on employee_departments.id= employees.employee_department_id",:group=>"employee_departments.id",:order=>"employee_departments.name").group_by(&:id)
      @departments=EmployeeDepartment.all(:select=>"id, name" ,:order=>'name ASC')
      @departments.each do |d|
        total=0.0
        total+=archived_employee_salary[d.id].nil?? 0 : archived_employee_salary[d.id][0].amount.to_f
        total+=employee_salary[d.id].nil?? 0 : employee_salary[d.id][0].amount.to_f
        d['amount']=total
      end
    end
  end



  def salary_employee
    if date_format_check
      employee_salary=FinanceTransaction.all(:select=>"amount,employees.first_name ,employees.middle_name,employees.last_name,employees.id as employee_id ,finance_transactions.id",:conditions=>{:title=>"Monthly Salary",:transaction_date=>@start_date..@end_date,:employees=>{:employee_department_id=>params[:id]}},:joins=>"INNER JOIN employees on employees.id= finance_transactions.payee_id",:include=>:monthly_payslips)
      archived_employee_salary=FinanceTransaction.all(:select=>"amount,archived_employees.first_name ,archived_employees.middle_name,archived_employees.last_name,archived_employees.id as employee_id ,finance_transactions.id",:conditions=>{:title=>"Monthly Salary",:transaction_date=>@start_date..@end_date,:archived_employees=>{:employee_department_id=>params[:id]}},:joins=>"INNER JOIN archived_employees on archived_employees.former_id= finance_transactions.payee_id",:include=>:monthly_payslips)
      @employees_salary=archived_employee_salary+employee_salary
      @employees_salary.each{|employee| employee['salary_date']= employee.monthly_payslips.first.salary_date}
      @employees_salary=@employees_salary.sort_by{|salary| salary.salary_date}
      @department = EmployeeDepartment.find(params[:id])
    end
  end

  def employee_payslip_monthly_report
    if date_format(params[:salary_date]).nil?
      flash[:notice]="#{t('bad_request')}"
      return redirect_to :action=>:monthly_report
    end
    @employee = Employee.find_in_active_or_archived(params[:employee_id])
    @currency_type = currency
    ft=FinanceTransaction.find(params[:finance_transaction_id])
    @monthly_payslips=MonthlyPayslip.find(:all,:conditions=>{:finance_transaction_id=>ft.id},:include=>:payroll_category) if ft
    @individual_payslips =  IndividualPayslipCategory.find(:all,:conditions=>["employee_id=? AND salary_date = ?", params[:employee_id], params[:salary_date]])
    @salary  = Employee.calculate_salary(@monthly_payslips, @individual_payslips)
  end

  def donations_report
    if date_format_check
      category_id = FinanceTransactionCategory.find_by_name("Donation").id
      @donations = FinanceTransaction.find(:all,:order => 'transaction_date desc', :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'and category_id ='#{category_id}'"])
    end

  end

  def fees_report
    month_date
    @batches= FinanceTransaction.total_fees(@start_date,@end_date)
    #fees_id = FinanceTransactionCategory.find_by_name('Fee').id
    #@fee_collections = FinanceFeeCollection.find(:all,:joins=>"INNER JOIN finance_fees ON finance_fees.fee_collection_id = finance_fee_collections.id INNER JOIN finance_transactions ON finance_transactions.finance_id = finance_fees.id AND finance_transactions.transaction_date >= '#{@start_date}' AND finance_transactions.transaction_date <= '#{@end_date}' AND finance_transactions.category_id = #{fees_id}",:group=>"finance_fee_collections.id")

  end

  def batch_fees_report
    month_date
    @fee_collection = FinanceFeeCollection.find(params[:id])
    @batch = Batch.find(params[:batch_id])
    @transaction =  FinanceTransaction.find(:all,:joins=>"INNER JOIN fee_transactions on fee_transactions.finance_transaction_id=finance_transactions.id INNER JOIN finance_fees on finance_fees.id=fee_transactions.finance_fee_id",:conditions=>["finance_fees.fee_collection_id='#{@fee_collection.id}' and finance_transactions.batch_id='#{@batch.id}' and finance_transactions.transaction_date >= '#{@start_date}' and finance_transactions.transaction_date <= '#{@end_date}'"])
  end

  def student_fees_structure

    month_date
    @student = Student.find(params[:id])
    @components = @student.get_fee_strucure_elements

  end

  # approve montly payslip ----------------------

  def approve_monthly_payslip
    @salary_dates = MonthlyPayslip.find(:all, :select => "distinct salary_date")

  end

  def one_click_approve
    @dates = MonthlyPayslip.find_all_by_salary_date(params[:salary_date],:conditions => ["is_approved = false"])
    @salary_date = params[:salary_date]
    render :update do |page|
      page.replace_html "approve",:partial=> "one_click_approve"
    end
  end

  def one_click_approve_submit
    dates = MonthlyPayslip.find_all_by_salary_date(Date.parse(params[:date]), :conditions=>["is_rejected is false"])

    dates.each do |d|
      d.approve(current_user.id,"Approved")
    end

    emp_ids = dates.map{|date| date.employee_id }.uniq.join(',')
    Delayed::Job.enqueue(PayslipTransactionJob.new(
        :salary_date => params[:date],
        :employee_id => emp_ids
      ))

    flash[:notice] = "#{t('flash8')}"
    redirect_to :action => "index"


  end

  def employee_payslip_approve
    dates = MonthlyPayslip.find_all_by_salary_date_and_employee_id(Date.parse(params[:id2]),params[:id])
    dates.each do |d|
      d.approve(current_user.id,params[:payslip_accept][:remark])
    end
    Delayed::Job.enqueue(PayslipTransactionJob.new(
        :salary_date => params[:id2],
        :employee_id => params[:id]
      ))
    flash[:notice] = "#{t('flash8')}"
    render :update do |page|
      page.reload
    end
  end
  def employee_payslip_reject
    dates = MonthlyPayslip.find_all_by_salary_date_and_employee_id(Date.parse(params[:id2]),params[:id])
    employee = Employee.find(params[:id])

    dates.each do |d|
      d.reject(current_user.id, params[:payslip_reject][:reason])
    end
    privilege = Privilege.find_by_name("PayslipPowers")
    hr_ids = privilege.user_ids
    subject = "#{t('payslip_rejected')}"
    body = "#{t('payslip_rejected_for')} "+ employee.first_name+" "+ employee.last_name+ " (#{t('employee_number')} : #{employee.employee_number})" +" #{t('for_the_month')} #{params[:id2].to_date.strftime("%B %Y")}"
    Delayed::Job.enqueue(DelayedReminderJob.new( :sender_id  => current_user.id,
        :recipient_ids => hr_ids,
        :subject=>subject,
        :body=>body ))
    render :update do |page|
      page.reload
    end
  end

  def employee_payslip_accept_form
    @id1 = params[:id]
    @id2 = params[:id2]
    respond_to do |format|
      format.js { render :action => 'accept' }
    end
  end

  def employee_payslip_reject_form
    @id1 = params[:id]
    @id2 = params[:id2]
    respond_to do |format|
      format.js { render :action => 'reject' }
    end
  end

  #view monthly payslip -------------------------------
  def view_monthly_payslip

    @departments = EmployeeDepartment.find(:all, :conditions=>"status = true", :order=> "name ASC")
    @salary_dates = MonthlyPayslip.find(:all,:select => "distinct salary_date")
    if request.post?
      post_data = params[:payslip]
      unless post_data.blank?
        if post_data[:salary_date].present? and post_data[:department_id].present?
          @payslips = MonthlyPayslip.find_and_filter_by_department(post_data[:salary_date],post_data[:department_id])
        else
          flash[:notice] = "#{t('select_salary_date')}"
          redirect_to :action=>"view_monthly_payslip"
        end
      end
    end
  end


  def view_employee_payslip
    @is_present_employee=true
    @is_present_employee=false if (Employee.find_by_id(params[:id]).nil?)
    @monthly_payslips = MonthlyPayslip.find(:all,:conditions=>["employee_id=? AND salary_date = ?",params[:id],params[:salary_date]],:include=>:payroll_category)
    @individual_payslips =  IndividualPayslipCategory.find(:all,:conditions=>["employee_id=? AND salary_date = ?",params[:id],params[:salary_date]])
    @salary  = Employee.calculate_salary(@monthly_payslips, @individual_payslips)
    @currency_type= currency
    if @monthly_payslips.blank?
      flash[:notice] = "No paylips found for this employee"
      redirect_to :controller => "finance", :action => "view_monthly_payslip"
    end
  end


  def search_ajax
    other_conditions = ""
    other_conditions += " AND employee_department_id = '#{params[:employee_department_id]}'" unless params[:employee_department_id] == ""
    other_conditions += " AND employee_category_id = '#{params[:employee_category_id]}'" unless params[:employee_category_id] == ""
    other_conditions += " AND employee_position_id = '#{params[:employee_position_id]}'" unless params[:employee_position_id] == ""
    other_conditions += " AND employee_grade_id = '#{params[:employee_grade_id]}'" unless params[:employee_grade_id] == ""
    if params[:query].length>= 3
      @employee = Employee.find(:all,
        :conditions => ["(first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                       OR employee_number LIKE ? OR (concat(first_name, \" \", last_name) LIKE ?))" + other_conditions,
          "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%",
          "#{params[:query]}", "#{params[:query]}"],
        :order => "first_name asc") unless params[:query] == ''
    else
      @employee = Employee.find(:all,
        :conditions => ["(employee_number LIKE ?)" + other_conditions,"#{params[:query]}%"],
        :order => "first_name asc") unless params[:query] == ''
    end
    render :layout => false
  end

  #asset-liability-----------

  def create_liability
    @liability = Liability.new(params[:liability])
    render :update do |page|
      if @liability.save
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg23')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @liability
        page.visual_effect(:highlight, 'form-errors')
      end
    end

  end

  def edit_liability
    @liability = Liability.find(params[:id])
  end

  def update_liability
    @liability = Liability.find(params[:id])
    @currency_type = currency

    render :update do |page|
      if @liability.update_attributes(params[:liability])
        @liabilities = Liability.find(:all,:conditions => 'is_deleted = 0')
        page.replace_html "liability_list", :partial => "liability_list"
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg24')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @liability
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def view_liability
    @liabilities = Liability.find(:all,:conditions => 'is_deleted = 0')
    @currency_type = currency
  end

  def liability_pdf
    @liabilities = Liability.find(:all,:conditions => 'is_deleted = 0')
    @currency_type = currency
    render :pdf => 'liability_report_pdf'
  end

  def delete_liability
    @liability = Liability.find(params[:id])
    @liability.update_attributes(:is_deleted => true)
    @liabilities = Liability.find(:all ,:conditions => 'is_deleted = 0')
    @currency_type = currency
    render :update do |page|
      page.replace_html "liability_list", :partial => "liability_list"
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg25')}</p>"
    end
  end

  def each_liability_view
    @liability = Liability.find(params[:id])
    @currency_type = currency
  end

  def create_asset
    @asset = Asset.new(params[:asset])
    render :update do |page|
      if @asset.save
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg20')}</p>"

      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @asset
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def view_asset
    @assets = Asset.find(:all,:conditions => 'is_deleted = 0')
    @currency_type = currency
  end

  def asset_pdf
    @assets = Asset.find(:all,:conditions => 'is_deleted = 0')
    @currency_type = currency
    render :pdf => 'asset_report_pdf'
  end

  def edit_asset
    @asset = Asset.find(params[:id])
  end

  def update_asset
    @asset = Asset.find(params[:id])
    @currency_type = currency

    render :update do |page|
      if @asset.update_attributes(params[:asset])
        @assets = Asset.find(:all,:conditions => 'is_deleted = 0')
        page.replace_html "asset_list", :partial => "asset_list"
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg21')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @asset
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def delete_asset
    @asset = Asset.find(params[:id])
    @asset.update_attributes(:is_deleted => true)
    @assets = Asset.all(:conditions => 'is_deleted = 0')
    @currency_type = currency
    render :update do |page|
      page.replace_html "asset_list", :partial => "asset_list"
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg22')}</p>"
    end
  end

  def each_asset_view
    @asset = Asset.find(params[:id])
    @currency_type = currency
  end
  #fees ----------------

  def master_fees
    @finance_fee_category = FinanceFeeCategory.new
    @finance_fee_particular = FinanceFeeParticular.new
    @batchs = Batch.active
    @master_categories = FinanceFeeCategory.find(:all,:conditions=> ["is_deleted = '#{false}' and is_master = 1 and batch_id=?",params[:batch_id]]) unless params[:batch_id].blank?
    @student_categories = StudentCategory.active
  end

  def master_category_new
    @finance_fee_category = FinanceFeeCategory.new
    @batches = Batch.active
    respond_to do |format|
      format.js { render :action => 'master_category_new' }
    end
  end

  def master_category_create
    if request.post?

      if params[:finance_fee_category][:category_batches_attributes].present?
        FinanceFeeCategory.transaction do
          @finance_fee_category = FinanceFeeCategory.find_or_create_by_name_and_description_and_is_deleted(params[:finance_fee_category][:name],params[:finance_fee_category][:description],false)


          @finance_fee_category.is_master = true
          if @finance_fee_category.update_attributes(params[:finance_fee_category])

          else
            @batch_error=true if params[:finance_fee_category][:category_batches_attributes].nil?
            @error = true
            raise ActiveRecord::Rollback
          end
        end
      else
        @batch_error=true
        @finance_fee_category = FinanceFeeCategory.new(params[:finance_fee_category])
        @finance_fee_category.valid?
        @error = true
      end
      @master_categories = FinanceFeeCategory.find(:all,:conditions=> ["is_deleted = '#{false}' and is_master = 1"])
      respond_to do |format|
        format.js { render :action => 'master_category_create' }
      end
    end
  end

  def master_category_edit
    @batch=Batch.find(params[:batch_id])
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    respond_to do |format|
      format.js { render :action => 'master_category_edit' }
    end
  end

  def master_category_update
    @batches=Batch.find(params[:batch_id])
    finance_fee_category = FinanceFeeCategory.find(params[:id])
    if (params[:finance_fee_category][:name]==finance_fee_category.name) and (params[:finance_fee_category][:description]==finance_fee_category.description)
      render :update do |page|
        @master_categories = @batches.finance_fee_categories.find(:all, :conditions =>["is_deleted = '#{false}' and is_master = 1 "])
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'categories', :partial => 'master_category_list'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg13')}</p>"
        @error=false
      end
    else
      attributes=finance_fee_category.attributes
      attributes.delete_if{|key,value| ["id","name","description","created_at"].include? key }
      #@finance_fee_category=FinanceFeeCategory.new(attributes)
      @error=true
      render :update do |page|
        FinanceFeeCategory.transaction do
          @finance_fee_category=FinanceFeeCategory.find_or_create_by_name_and_description_and_is_deleted(params[:finance_fee_category][:name],params[:finance_fee_category][:description],false)
          if @finance_fee_category.update_attributes(attributes)
            @finance_fee_category.create_associates(finance_fee_category.id,@batches.id)
            cat_batch=CategoryBatch.find_by_finance_fee_category_id_and_batch_id(finance_fee_category.id,@batches.id)
            cat_batch.destroy if cat_batch
            finance_fee_category.update_attributes(:is_deleted => true) unless finance_fee_category.category_batches.present?
            @master_categories = @batches.finance_fee_categories.find(:all, :conditions =>["is_deleted = '#{false}' and is_master = 1 "])

            if @finance_fee_category.check_category_name_exists(@batches)
              page.replace_html 'form-errors', :text => ''
              page << "Modalbox.hide();"
              page.replace_html 'categories', :partial => 'master_category_list'
              page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg13')}</p>"
              @error=false
            else
              @error=true
              @finance_fee_category.errors.add_to_base(t('name_already_taken'))
            end
          end
          if @error
            page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_category

            page.visual_effect(:highlight, 'form-errors')
            raise ActiveRecord::Rollback
          end


        end
      end

    end
  end


  def master_category_particulars
    @batch=Batch.find(params[:batch_id])
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    #categories=FinanceFeeCategory.find(:all,:include=>:category_batches,:conditions=>"name=@finance_fee_category.name and description=@finance_fee_category.description and is_deleted=#{false}").map{|d| d if d.category_batches.empty?}.compact
    #    categories=FinanceFeeCategory.find(:all,:include=>:category_batches,:conditions=>"name='#{@finance_fee_category.name}' and description='#{@finance_fee_category.description}' and is_deleted=#{false}").uniq.map{|d| d if d.batch_id==@batch.id}.compact
    #    if categories.present?
    #      @finance_fee_category = FinanceFeeCategory.find_by_name_and_batch_id_and_is_deleted(@finance_fee_category.name,@batch.id,false)
    #    end
    #@particulars = FinanceFeeParticular.paginate(:page => params[:page],:joins=>"INNER JOIN finance_fee_categories on finance_fee_categories.id=finance_fee_particulars.finance_fee_category_id",:conditions => ["finance_fee_particulars.is_deleted = '#{false}' and finance_fee_categories.name = '#{@finance_fee_category.name}' and finance_fee_categories.description = '#{@finance_fee_category.description}' and finance_fee_particulars.batch_id='#{@batch.id}' "])
    @particulars = FinanceFeeParticular.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' and batch_id='#{@batch.id}' "])

  end
  def master_category_particulars_edit
    @finance_fee_particular= FinanceFeeParticular.find(params[:id])
    @student_categories = StudentCategory.active
    unless @finance_fee_particular.student_category.present? and @student_categories.collect(&:name).include?(@finance_fee_particular.student_category.name)
      current_student_category=@finance_fee_particular.student_category
      @student_categories << current_student_category if current_student_category.present?
    end
    respond_to do |format|
      format.js { render :action => 'master_category_particulars_edit' }
    end
  end

  def master_category_particulars_update
    @feeparticulars = FinanceFeeParticular.find( params[:id])
    render :update do |page|
      #params[:finance_fee_particular][:student_category_id]="" if params[:finance_fee_particular][:student_category_id].nil?
      if @feeparticulars.collection_exist
        if @feeparticulars.update_attributes(params[:finance_fee_particular])
          @finance_fee_category = FinanceFeeCategory.find(@feeparticulars.finance_fee_category_id)
          @particulars = FinanceFeeParticular.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' and batch_id='#{@feeparticulars.batch_id}'"])
          page.replace_html 'form-errors', :text => ''
          page << "Modalbox.hide();"
          page.replace_html 'categories', :partial => 'master_particulars_list'
          page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg14')}</p>"
        else
          page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @feeparticulars
          page.visual_effect(:highlight, 'form-errors')
        end
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @feeparticulars
        page.visual_effect(:highlight, 'form-errors')
      end
    end
    #    respond_to do |format|
    #      format.js { render :action => 'master_category_particulars' }
    #    end
  end
  def master_category_particulars_delete
    @feeparticular = FinanceFeeParticular.find( params[:id])
    #discounts=@feeparticular.finance_fee_category.fee_discounts.all(:conditions=>"batch_id=#{@feeparticular.batch_id}")
    @error=true unless @feeparticular.delete_particular

    @finance_fee_category = FinanceFeeCategory.find(@feeparticular.finance_fee_category_id)
    @particulars = FinanceFeeParticular.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' and batch_id='#{@feeparticular.batch_id}' "])
    respond_to do |format|
      format.js { render :action => 'master_category_particulars' }
    end
  end
  def master_category_delete
    @error=false
    @batches=Batch.find(params[:batch_id])
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @catbatch=CategoryBatch.find_by_finance_fee_category_id_and_batch_id(params[:id],params[:batch_id])
    unless @catbatch.destroy
      @catbatch.errors.add_to_base(t('fee_collection_exists_cant_delete_this_category'))
      @error=true
    end
    @finance_fee_category.update_attributes(:is_deleted => true) unless @finance_fee_category.category_batches.present?
    #@finance_fee_category.delete_particulars
    @master_categories = @batches.finance_fee_categories.find(:all, :conditions =>["is_deleted = '#{false}' and is_master = 1 "])
    respond_to do |format|
      format.js { render :action => 'master_category_delete' }
    end
  end

  def show_master_categories_list
    unless params[:id].empty?
      @finance_fee_category = FinanceFeeCategory.new
      @finance_fee_particular = FinanceFeeParticular.new
      @batches = Batch.find params[:id] unless params[:id] == ""
      @master_categories =@batches.finance_fee_categories.find(:all, :conditions =>["is_deleted = '#{false}' and is_master = 1 "])
      #@master_categories = FinanceFeeCategory.find(:all,:conditions=> ["is_deleted = '#{false}' and is_master = 1 and batch_id=?",params[:id]])
      @student_categories = StudentCategory.active

      render :update do |page|
        page.replace_html 'categories', :partial => 'master_category_list'
      end
    else
      render :update do |page|
        page.replace_html 'categories', :text=>""
      end
    end
  end

  def fees_particulars_new
    @finance_fee_particular =FinanceFeeParticular.new()
    @fees_categories = FinanceFeeCategory.find(:all,:group=>'concat(name,description)',:conditions=> "is_deleted = 0 and is_master = 1")
    #@fees_categories.reject!{|f|f.batch.is_deleted or !f.batch.is_active }
    @student_categories = StudentCategory.active
    @all=true
    @student=false
    @category=false
  end

  def list_category_batch
    fee_category=FinanceFeeCategory.find(params[:category_id])
    @batches= Batch.find(:all,:joins=>"INNER JOIN `category_batches` ON `batches`.id = `category_batches`.batch_id INNER JOIN finance_fee_categories on finance_fee_categories.id=category_batches.finance_fee_category_id INNER JOIN courses on courses.id=batches.course_id",:conditions=>"finance_fee_categories.name = '#{fee_category.name}' and finance_fee_categories.description = '#{fee_category.description}'",:order=>"courses.code ASC")
    #@batches=fee_category.batches.all(:order=>"name ASC")
    render :update do |page|
      page.replace_html 'list-category-batch', :partial => 'list_category_batch'
    end
  end

  def fees_particulars_create
    if request.get?
      redirect_to :action => "fees_particulars_new"
    else
      @finance_category=FinanceFeeCategory.find_by_id(params[:finance_fee_particular][:finance_fee_category_id])
      @batches= Batch.find(:all,:joins=>"INNER JOIN `category_batches` ON `batches`.id = `category_batches`.batch_id INNER JOIN finance_fee_categories on finance_fee_categories.id=category_batches.finance_fee_category_id INNER JOIN courses on courses.id=batches.course_id",:conditions=>"finance_fee_categories.name = '#{@finance_category.name}' and finance_fee_categories.description = '#{@finance_category.description}'",:order=>"courses.code ASC") if  @finance_category
      if params[:particular] and params[:particular][:batch_ids]
        batches=Batch.find(params[:particular][:batch_ids])
        @cat_ids=params[:particular][:batch_ids]
        if params[:particular][:receiver_id].present?
          all_admission_no = admission_no=params[:particular][:receiver_id].split(',')
          all_students = batches.map{|b| b.students.map{|stu| stu.admission_no}}.flatten
          rejected_admission_no = admission_no.select{|adm| !all_students.include? adm}
          unless (rejected_admission_no.empty?)
            @error = true
            @finance_fee_particular = FinanceFeeParticular.new(params[:finance_fee_particular])
            @finance_fee_particular.batch_id=1
            @finance_fee_particular.save
            @finance_fee_particular.errors.add_to_base("#{rejected_admission_no.join(',')} #{t('does_not_belong_to_batch')} #{batches.map{|batch| batch.full_name}.join(',')}")
          end

          selected_admission_no = all_admission_no.select{|adm| all_students.include? adm}
          selected_admission_no.each do |a|
            s = Student.find_by_admission_no(a)
            if s.nil?
              @error = true
              @finance_fee_particular = FinanceFeeParticular.new(params[:finance_fee_particular])
              @finance_fee_particular.save
              @finance_fee_particular.errors.add_to_base("#{a} #{t('does_not_exist')}")
            end
          end
          unless @error

            selected_admission_no.each do |a|
              s = Student.find_by_admission_no(a)
              batch=s.batch
              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @finance_fee_particular.receiver_id=s.id
              @error = true unless @finance_fee_particular.save
            end
          end
        else
          batches.each do |batch|
            if params[:finance_fee_particular][:receiver_type]=="Batch"

              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @finance_fee_particular.receiver_id=batch.id
              @error = true unless @finance_fee_particular.save
            elsif params[:finance_fee_particular][:receiver_type]=="StudentCategory"
              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @error = true unless @finance_fee_particular.save
              @finance_fee_particular.errors.add_to_base("#{t('category_cant_be_blank')}") if params[:finance_fee_particular][:receiver_id]==""
            else

              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @error = true unless @finance_fee_particular.save
              @finance_fee_particular.errors.add_to_base("#{t('admission_no_cant_be_blank')}")
            end

          end
        end
      else
        @error=true
        @finance_fee_particular =FinanceFeeParticular.new(params[:finance_fee_particular])
        @finance_fee_particular.save
      end

      if @error
        @fees_categories = FinanceFeeCategory.find(:all,:group=>:name,:conditions=> "is_deleted = 0 and is_master = 1")
        @student_categories = StudentCategory.active

        @render=true
        if params[:finance_fee_particular][:receiver_type]=="Student"
          @student=true
        elsif params[:finance_fee_particular][:receiver_type]=="StudentCategory"
          @category=true
        else
          @all=true
        end

        render :action => 'fees_particulars_new'
      else
        flash[:notice]="#{t('particulars_created_successfully')}"
        redirect_to :action => "fees_particulars_new"
      end
    end
  end

  def fees_particulars_new2
    @batch=Batch.find(params[:batch_id])
    @fees_category = FinanceFeeCategory.find(params[:category_id])
    @student_categories = StudentCategory.active
    respond_to do |format|
      format.js { render :action => 'fees_particulars_new2' }
    end
  end

  def fees_particulars_create2
    batch=Batch.find(params[:finance_fee_particular][:batch_id])
    if params[:particular] and params[:particular][:receiver_id]

      all_admission_no = admission_no=params[:particular][:receiver_id].split(',')
      all_students = batch.students.map{|stu| stu.admission_no}.flatten
      rejected_admission_no = admission_no.select{|adm| !all_students.include? adm}
      unless (rejected_admission_no.empty?)
        @error = true
        @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
        @finance_fee_particular.save
        @finance_fee_particular.errors.add_to_base("#{rejected_admission_no.join(',')} #{t('does_not_belong_to_batch')} #{batch.full_name}")
      end

      selected_admission_no = all_admission_no.select{|adm| all_students.include? adm}
      selected_admission_no.each do |a|
        s = Student.find_by_admission_no(a)
        if s.nil?
          @error = true
          @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
          @finance_fee_particular.save
          @finance_fee_particular.errors.add_to_base("#{a} #{t('does_not_exist')}")
        end
      end
      unless @error
        unless selected_admission_no.present?
          @finance_fee_particular=batch.finance_fee_particulars.new(params[:finance_fee_particular])
          @finance_fee_particular.save
          @finance_fee_particular.errors.add_to_base("#{t('admission_no_cant_be_blank')}")
          @error = true
        else
          selected_admission_no.each do |a|
            s = Student.find_by_admission_no(a)
            @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
            @finance_fee_particular.receiver_id=s.id
            @error = true unless @finance_fee_particular.save
          end
        end
      end
    elsif params[:finance_fee_particular][:receiver_type]=="Batch"

      @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
      @finance_fee_particular.receiver_id=batch.id
      @error = true unless @finance_fee_particular.save
    else
      @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
      @error = true unless @finance_fee_particular.save
      @finance_fee_particular.errors.add_to_base("#{t('category_cant_be_blank')}") if params[:finance_fee_particular][:receiver_id]==""
    end
    @batch=batch
    @finance_fee_category = FinanceFeeCategory.find(params[:finance_fee_particular][:finance_fee_category_id])
    @particulars = FinanceFeeParticular.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' and batch_id='#{@batch.id}' "])

  end

  def additional_fees_create_form
    @batches = Batch.active
    @student_categories = StudentCategory.active
  end

  def additional_fees_create

    batch = params[:additional_fees][:batch_id] unless params[:additional_fees][:batch_id].nil?
    # batch ||=[]
    @batches = Batch.active
    @user = current_user
    @students = Student.find_all_by_batch_id(batch) unless batch.nil?
    @additional_category = FinanceFeeCategory.new(
      :name => params[:additional_fees][:name],
      :description => params[:additional_fees][:description],
      :batch_id => params[:additional_fees][:batch_id]
    )
    if params[:additional_fees][:due_date].to_date >= params[:additional_fees][:end_date].to_date
      if @additional_category.save && params[:additional_fees][:start_date].strip.length!=0 && params[:additional_fees][:due_date].strip.length!=0 && params[:additional_fees][:end_date].strip.length!=0
        @collection_date = FinanceFeeCollection.create(
          :name => @additional_category.name,
          :start_date => params[:additional_fees][:start_date],
          :end_date => params[:additional_fees][:end_date],
          :due_date => params[:additional_fees][:due_date],
          :batch_id => params[:additional_fees][:batch_id],
          :fee_category_id => @additional_category.id
        )
        body = "<p>#{t('fee_submission_date_for')} "+@additional_category.name+" #{t('has_been_published')} <br />
                               #{t('fees_submiting_date_starts_on')}< br />
                               #{t('start_date')} : "+@collection_date.start_date.to_s+" <br />"+
          "#{t('end_date')} : "+@collection_date.end_date.to_s+" <br />"+
          "#{t('due_date')} : "+@collection_date.due_date.to_s
        subject = "#{t('fees_submission_date')}"
        @due_date = @collection_date.due_date.strftime("%Y-%b-%d") +  " 00:00:00"
        unless batch.empty?
          @students.each do |s|
            FinanceFee.create(:student_id => s.id,:fee_collection_id => @collection_date.id)
            Reminder.create(:sender=>@user.id, :recipient=>s.id, :subject=> subject,
              :body => body, :is_read=>false, :is_deleted_by_sender=>false,:is_deleted_by_recipient=>false)
          end
          Event.create(:title=> "#{t('fees_due')}", :description =>@additional_category.name, :start_date => @due_date.to_datetime, :end_date => @due_date.to_datetime, :is_due => true, :origin => @collection_date)
        else
          @batches.each do |b|
            @students = Student.find_all_by_batch_id(b.id)
            @students.each do |s|
              FinanceFee.create(:student_id => s.id,:fee_collection_id => @collection_date.id)
              Reminder.create(:sender=>@user.id, :recipient=>s.user.id, :subject=> subject,
                :body => body, :is_read=>false, :is_deleted_by_sender=>false,:is_deleted_by_recipient=>false)
            end
          end
          Event.create(:title=> "#{t('fees_due')}", :description =>@additional_category.name, :start_date => @due_date.to_datetime, :end_date => @due_date.to_datetime, :is_due => true, :origin => @collection_date)
        end
        flash[:notice] = "#{t('flash9')}"
        redirect_to(:action => "add_particulars" ,:id => @collection_date.id)
      else
        flash[:notice] = "#{t('flash10')}"
        redirect_to :action => "additional_fees_create_form"
      end
    else
      flash[:notice] = "#{t('flash11')}"
      redirect_to :action => "additional_fees_create_form"
    end
  end

  def additional_fees_edit
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @collection_date = FinanceFeeCollection.find_by_fee_category_id(@finance_fee_category.id)
    respond_to do |format|
      format.js { render :action => 'additional_fees_edit' }
    end
    flash[:notice] = "#{t('flash26')}"
  end

  def additional_fees_update
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @collection_date = FinanceFeeCollection.find_by_fee_category_id(@finance_fee_category.id)
    #    render :update do |page|

    if @finance_fee_category.update_attributes(:name =>params[:finance_fee_category][:name], :description =>params[:finance_fee_category][:description])
      if @collection_date.update_attributes(:start_date=>params[:additional_fees][:start_date], :end_date=>params[:additional_fees][:end_date],:due_date=>params[:additional_fees][:due_date])
        @collection_date.event.update_attributes(:start_date=>@collection_date.due_date.to_datetime, :end_date=>@collection_date.due_date.to_datetime)
        @additional_categories = FinanceFeeCategory.find(:all, :conditions =>["is_deleted = '#{false}' and is_master = '#{false}' and batch_id = '#{@finance_fee_category.batch_id}'"])
        #        page.replace_html 'form-errors', :text => ''
        #        page << "Modalbox.hide();"
        #        page.replace_html 'particulars', :partial => 'additional_fees_list'
        #        end
      else
        @error = true
      end
    else
      #        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_category
      #        page.visual_effect(:highlight, 'form-errors')
      @error = true
    end
    #    end
  end

  def additional_fees_delete
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @finance_fee_category.update_attributes(:is_deleted => true)
    @finance_fee_collection = FinanceFeeCollection.find_by_fee_category_id(params[:id])
    @finance_fee_collection.update_attributes(:is_deleted => true)
    @finance_fee_category.delete_particulars
    # redirect_to :action => "additional_fees_list"
    @additional_categories = FinanceFeeCategory.find(:all, :conditions =>["is_deleted = '#{false}' and is_master = '#{false}' and batch_id = '#{@finance_fee_category.batch_id}'"])
    respond_to do |format|
      format.js { render :action => 'additional_fees_delete' }
      flash[:notice] = "#{t('flash27')}"
    end
  end

  def add_particulars
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)
    @student_categories = StudentCategory.active
    @finance_fee_particulars = FeeCollectionParticular.new
    @finance_fee_particulars_list = FeeCollectionParticular.find(:all,:conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}'"])
  end

  def add_particulars_new
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)
    @student_categories = StudentCategory.active
    @finance_fee_particulars = FeeCollectionParticular.new
  end

  def add_particulars_create
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)
    @error = false
    unless params[:finance_fee_particulars][:admission_no].nil?
      unless params[:finance_fee_particulars][:admission_no].empty?
        posted_params = params[:finance_fee_particulars]
        admission_no = posted_params[:admission_no].split(",")
        posted_params.delete "admission_no"
        err = ""
        admission_no.each do |a|
          posted_params["admission_no"] = a.to_s
          @finance_fee_particulars = FeeCollectionParticular.new(posted_params)
          @finance_fee_particulars.finance_fee_collection_id = @collection_date.id
          s = Student.find_by_admission_no(a)
          unless s.nil?
            if (s.batch_id == @collection_date.batch_id) or (@collection_date.batch_id.nil?)
              unless @finance_fee_particulars.save
                @error = true
              end
            else
              @error = true
              err = err + "#{a}#{t('does_not_belong_to_batch')} #{@collection_date.batch.full_name}. <br />"
            end
          else
            @error = true
            err = err + "#{a} #{t('does_not_exist')}<br />"
          end
        end
        @finance_fee_particulars.errors.add(:admission_no," #{t('invalid')} : <br />" + err) if @error==true
        @finance_fee_particulars_list = FeeCollectionParticular.find(:all,:conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}'"])  unless @error== true
      else
        @error = true
        @finance_fee_particulars = FeeCollectionParticular.new(params[:finance_fee_particulars])
        @finance_fee_particulars.valid?
        @finance_fee_particulars.errors.add(:admission_no,"#{t('is_blank')}")
      end
    else
      @finance_fee_particulars = FeeCollectionParticular.new(params[:finance_fee_particulars])
      @finance_fee_particulars.finance_fee_collection_id = @collection_date.id
      unless @finance_fee_particulars.save
        @error = true
      else
        @finance_fee_particulars_list = FeeCollectionParticular.find(:all,:conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}'"])
      end

    end
  end

  def student_or_student_category
    @student_categories = StudentCategory.active

    select_value = params[:select_value]

    if select_value == "StudentCategory"
      render :update do |page|
        page.replace_html "student", :partial => "student_category_particulars"
      end
    elsif select_value == "Student"
      render :update do |page|
        page.replace_html "student", :partial => "student_admission_particulars"
      end
    elsif select_value == "Batch"
      render :update do |page|
        page.replace_html "student", :text=>""
      end
    end
  end

  def additional_fees_list
    @batchs=Batch.active
    #@additional_categories = FinanceFeeCategory.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and is_master = '#{false}'"])
  end

  def show_additional_fees_list
    @additional_categories = FinanceFeeCategory.find(:all,:conditions => ["is_deleted = '#{false}' and is_master = '#{false}' and batch_id=?",params[:id]])
    render :update do |page|
      page.replace_html 'particulars', :partial =>'additional_fees_list'
    end
  end

  def additional_particulars
    @additional_category = FinanceFeeCategory.find(params[:id])
    @collection_date = FinanceFeeCollection.find_by_fee_category_id(@additional_category.id)
    @particulars = FeeCollectionParticular.find(:all,:conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}' "])
  end

  def add_particulars_edit
    @finance_fee_particulars = FeeCollectionParticular.find(params[:id])
  end

  def add_particulars_update
    @finance_fee_particulars = FeeCollectionParticular.find(params[:id])
    render :update do |page|
      if @finance_fee_particulars.update_attributes(params[:finance_fee_particulars])
        @collection_date = @finance_fee_particulars.finance_fee_collection
        @additional_category =@collection_date.fee_category
        @particulars = FeeCollectionParticular.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}' "])
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'particulars', :partial => 'additional_particulars_list'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg32')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_particulars
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def add_particulars_delete
    @finance_fee_particulars = FeeCollectionParticular.find(params[:id])
    @finance_fee_particulars.update_attributes(:is_deleted => true)
    @collection_date = @finance_fee_particulars.finance_fee_collection
    @additional_category =@collection_date.fee_category
    @particulars = FeeCollectionParticular.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}' "])
    render :update do |page|
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('particulars_deleted_successfully')}</p>"
      page.replace_html 'particulars', :partial => 'additional_particulars_list'
    end
  end

  def fee_collection_batch_update
    if params[:id].present?
      @fee_category=FinanceFeeCategory.find(params[:id])
      @batches= Batch.find(:all,:joins=>"INNER JOIN `finance_fee_particulars` ON `batches`.id = `finance_fee_particulars`.batch_id INNER JOIN finance_fee_categories on finance_fee_categories.id=finance_fee_particulars.finance_fee_category_id INNER JOIN courses on courses.id=batches.course_id",:conditions=>"finance_fee_categories.name = '#{@fee_category.name}' and finance_fee_categories.description = '#{@fee_category.description}' and finance_fee_particulars.is_deleted=#{false}",:order=>"courses.code ASC").uniq
    end
    render :update do |page|
      page.replace_html "batchs" ,:partial => "fee_collection_batchs"
    end

  end

  def fee_collection_new
    @fines=Fine.active
    @fee_categories=FinanceFeeCategory.find(:all,:joins=>"INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=finance_fee_categories.id AND finance_fee_particulars.is_deleted = 0 INNER JOIN batches on batches.id=finance_fee_particulars.batch_id AND batches.is_active = 1 AND batches.is_deleted = 0 AND finance_fee_categories.is_deleted=0",:group=>'concat(finance_fee_categories.name,finance_fee_categories.description)')
    @finance_fee_collection = FinanceFeeCollection.new
  end

  def fee_collection_create

    @user = current_user
    @fee_categories=FinanceFeeCategory.find(:all,:joins=>"INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=finance_fee_categories.id AND finance_fee_particulars.is_deleted = 0 INNER JOIN batches on batches.id=finance_fee_particulars.batch_id AND batches.is_active = 1 AND batches.is_deleted = 0 AND finance_fee_categories.is_deleted=0",:group=>'finance_fee_categories.name')
    unless params[:finance_fee_collection].nil?
      fee_category_name = params[:finance_fee_collection][:fee_category_id]
      @fee_category = FinanceFeeCategory.find_all_by_id(fee_category_name, :conditions=>['is_deleted is false'])
    end
    category =[]
    @finance_fee_collection = FinanceFeeCollection.new
    if request.post?

      Delayed::Job.enqueue(DelayedFeeCollectionJob.new(@user,params[:finance_fee_collection],params[:fee_collection]))


      flash[:notice]="Collection is in queue. <a href='/scheduled_jobs/FinanceFeeCollection/1'>Click Here</a> to view the scheduled job."
      #flash[:notice] = t('flash_msg33')

    end
    redirect_to :action => 'fee_collection_new'
  end

  def fee_collection_view
    @batchs = Batch.active
  end

  def fee_collection_dates_batch
    if params[:id].present?
      @batch= Batch.find(params[:id])
      @finance_fee_collections = @batch.finance_fee_collections
      render :update do |page|
        page.replace_html 'fee_collection_dates', :partial => 'fee_collection_dates_batch'
      end
    else
      render :update do |page|
        page.replace_html 'fee_collection_dates', :text => ''
      end
    end
  end

  def fee_collection_edit
    @finance_fee_collection = FinanceFeeCollection.find params[:id]
    @batch=Batch.find(params[:batch_id])
  end


  def fee_collection_update
    @batch=Batch.find(params[:batch_id])
    @user = current_user
    finance_fee_collection = FinanceFeeCollection.find params[:id]
    attributes=finance_fee_collection.attributes
    attributes.delete_if{|key,value| ["id","name","start_date","end_date","due_date","created_at"].include? key }
    @finance_fee_collection=FinanceFeeCollection.new(attributes)
    @error=true
    events = @finance_fee_collection.event
    @students=Student.find(:all,:joins=>"INNER JOIN finance_fees on finance_fees.student_id=students.id",:conditions=>"students.batch_id=#{@batch.id} and finance_fees.fee_collection_id=#{finance_fee_collection.id}")
    render :update do |page|
      FinanceFeeCollection.transaction do
        # if params[:finance_fee_collection][:due_date].to_date >= params[:finance_fee_collection][:end_date].to_date
        finance_fee_collection.delete_collection(@batch.id)
        if @finance_fee_collection.update_attributes(params[:finance_fee_collection])
          new_event =  Event.create(:title=> "Fees Due", :description =>@finance_fee_collection.name, :start_date => @finance_fee_collection.due_date.to_datetime, :end_date => @finance_fee_collection.due_date.to_datetime, :is_due => true , :origin=>@finance_fee_collection)
          BatchEvent.create(:event_id => new_event.id, :batch_id => @batch.id )
          FeeCollectionBatch.create(:finance_fee_collection_id=>@finance_fee_collection.id,:batch_id=>@batch.id)
          @error=false
          events.update_attributes(:start_date=> @finance_fee_collection.due_date.to_datetime, :end_date=> @finance_fee_collection.due_date.to_datetime, :description=>params[:finance_fee_collection][:name]) unless events.blank?
          fee_category_name = @finance_fee_collection.fee_category.name
          subject = "#{t('fees_submission_date')}"
          body = "<p><b>#{t('fee_submission_date_for')} <i>"+fee_category_name+"</i> #{t('has_been_updated')}</b> <br /><br/>
                                #{t('start_date')} : "+@finance_fee_collection.start_date.to_s+"<br />"+
            " #{t('end_date')} : "+@finance_fee_collection.end_date.to_s+" <br />"+
            " #{t('due_date')} : "+@finance_fee_collection.due_date.to_s+" <br /><br /><br />"+
            " #{t('check_your')} #{t('fee_structure')} <br/><br/><br/> "
          recipient_ids = []

          @students.each do |s|

            unless s.has_paid_fees
              FinanceFee.new_student_fee(@finance_fee_collection,s)
              recipient_ids << s.user.id if s.user
            end
          end

          Delayed::Job.enqueue(DelayedReminderJob.new( :sender_id  => @user.id,
              :recipient_ids => recipient_ids,
              :subject=>subject,
              :body=>body ))
          @finance_fee_collections = @batch.finance_fee_collections.find(:all,:conditions => ["is_deleted = '#{false}'"])
          page.replace_html 'form-errors', :text => ''
          page << "Modalbox.hide();"
          page.replace_html 'fee_collection_dates', :partial => 'fee_collection_list'
          page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('finance.flash12')}</p>"
        else
          raise ActiveRecord::Rollback

        end
        #      else
        #        page.replace_html 'form-errors', :text => "<div id='error-box'><ul><li>#{t('flash_msg15')} .</li></ul></div>"
        #        flash[:notice]=""
        #
        #      end
      end
      if @error
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_collection
        page.visual_effect(:highlight, 'form-errors')
      end
    end
    @finance_fee_collections = @batch.finance_fee_collections.find(:all,:conditions => ["is_deleted = '#{false}'"])
  end

  def fee_collection_delete
    @batch=Batch.find(params[:batch_id])
    @finance_fee_collection = FinanceFeeCollection.find params[:id]
    @finance_fee_collection.delete_collection(@batch.id)
    @finance_fee_collections = @batch.finance_fee_collections.find(:all,:conditions => ["is_deleted = '#{false}'"])
  end

  #fees_submission-----------------------------------

  def fees_submission_batch
    @batches = Batch.find(:all,:conditions=>{:is_deleted=>false,:is_active=>true},:joins=>:course,:select=>"`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:order=>"course_full_name")
    @inactive_batches = Batch.find(:all,:conditions=>{:is_deleted=>false,:is_active=>false},:joins=>:course,:select=>"`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:order=>"course_full_name")
    @dates = []
  end

  def update_fees_collection_dates

    @batch = Batch.find(params[:batch_id])
    @dates = @batch.finance_fee_collections
    render :update do |page|
      page.replace_html "fees_collection_dates", :partial => "fees_collection_dates"
    end
  end

  def load_fees_submission_batch

    @batch   = Batch.find(params[:batch_id])
    @date    =  @fee_collection = FinanceFeeCollection.find(params[:date])
    student_ids=@date.finance_fees.find(:all,:conditions=>"batch_id='#{@batch.id}'").collect(&:student_id).join(',')

    @dates   = @batch.finance_fee_collections


    if params[:student]
      @student = Student.find(params[:student])
      @fee = FinanceFee.first(:conditions=>"fee_collection_id = #{@date.id}" ,:joins=>"INNER JOIN students ON finance_fees.student_id = '#{@student.id}'")
    else
      @fee = FinanceFee.first(:conditions=>"fee_collection_id = #{@date.id} and FIND_IN_SET(students.id,'#{ student_ids}')" ,:joins=>'INNER JOIN students ON finance_fees.student_id = students.id')
    end
    unless @fee.nil?

      @student ||= @fee.student
      @prev_student = @student.previous_fee_student(@date.id,student_ids)
      @next_student = @student.next_fee_student(@date.id,student_ids)
      @financefee = @student.finance_fee_by_date @date
      @due_date = @fee_collection.due_date
      @paid_fees = @fee.finance_transactions
      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted = false"])

      @fee_particulars = @date.finance_fee_particulars.all(:conditions=>"batch_id=#{@batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@batch) }
      @discounts=@date.fee_discounts.all(:conditions=>"batch_id=#{@batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@batch) }

      @total_discount = 0
      @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
      @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?
      bal=(@total_payable-@total_discount).to_f
      days=(Date.today-@date.due_date.to_date).to_i
      auto_fine=@date.fine
      if days > 0 and auto_fine
        @fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],:order=>'fine_days ASC')
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
      end
      @fine_amount=0 if @financefee.is_paid
      render :update do |page|
        page.replace_html "student", :partial => "student_fees_submission"
      end
    else
      render :update do |page|
        page.replace_html "student", :text => '<p class="flash-msg">No students have been assigned this fee.</p>'
      end
    end
  end

  def update_ajax

    @batch   = Batch.find(params[:batch_id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    student_ids=@date.finance_fees.find(:all,:conditions=>"batch_id='#{@batch.id}'").collect(&:student_id).join(',')
    @dates = @batch.finance_fee_collections
    @student = Student.find(params[:student]) if params[:student]
    @student ||= FinanceFee.first(:conditions=>"fee_collection_id = #{@date.id}",:joins=>'INNER JOIN students ON finance_fees.student_id = students.id').student
    @prev_student = @student.previous_fee_student(@date.id,student_ids)
    @next_student = @student.next_fee_student(@date.id,student_ids)
    @due_date = @fee_collection.due_date
    total_fees =0

    @financefee = @student.finance_fee_by_date @date

    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @date.finance_fee_particulars.all(:conditions=>"batch_id=#{@batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@batch) }
    @discounts=@date.fee_discounts.all(:conditions=>"batch_id=#{@batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@batch)}
    @total_discount = 0
    @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
    @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?


    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],:order=>'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
    end



    total_fees =@financefee.balance.to_f+params[:special_fine].to_f

    unless params[:fine].nil?
      unless @financefee.is_paid == true
        total_fees += params[:fine].to_f
      else
        total_fees = params[:fine].to_f
      end
    end
    unless params[:fees][:fees_paid].to_f <= 0
      unless params[:fees][:payment_mode].blank?
        unless FedenaPrecision.set_and_modify_precision(params[:fees][:fees_paid]).to_f > FedenaPrecision.set_and_modify_precision(total_fees).to_f
          transaction = FinanceTransaction.new
          (@financefee.balance.to_f > params[:fees][:fees_paid].to_f ) ? transaction.title = "#{t('receipt_no')}. (#{t('partial')}) F#{@financefee.id}" :  transaction.title = "#{t('receipt_no')}. F#{@financefee.id}"
          transaction.category = FinanceTransactionCategory.find_by_name("Fee")
          transaction.payee = @student
          transaction.amount = params[:fees][:fees_paid].to_f
          transaction.fine_amount = params[:fine].to_f
          transaction.fine_included = true  unless params[:fine].nil?
          if params[:special_fine] and FedenaPrecision.set_and_modify_precision(total_fees)==params[:fees][:fees_paid]
            transaction.fine_amount = params[:fine].to_f+params[:special_fine].to_f
            transaction.fine_included = true
            @fine_amount=0
          end
          transaction.finance = @financefee
          transaction.transaction_date = Date.today
          transaction.payment_mode = params[:fees][:payment_mode]
          transaction.payment_note = params[:fees][:payment_note]
          transaction.save

          is_paid =@financefee.balance==0 ? true : false
          @financefee.update_attributes( :is_paid=>is_paid)

          @paid_fees = @financefee.finance_transactions
        else
          @paid_fees = @financefee.finance_transactions
          @financefee.errors.add_to_base("#{t('flash19')}")
        end
      else
        @paid_fees = @financefee.finance_transactions
        @financefee.errors.add_to_base("#{t('select_one_payment_mode')}")
      end
    else
      @paid_fees = @financefee.finance_transactions
      @financefee.errors.add_to_base("#{t('flash23')}")
    end
    render :update do |page|
      page.replace_html "student", :partial => "student_fees_submission"

    end

  end

  def student_fee_receipt_pdf
    @batch=Batch.find(params[:batch_id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:id2])
    @student = Student.find(params[:id])
    @financefee = @student.finance_fee_by_date @date
    @due_date = @fee_collection.due_date

    @paid_fees = @financefee.finance_transactions
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted = false"])
    @currency_type = currency

    @fee_particulars = @date.finance_fee_particulars.all(:conditions=>"batch_id=#{@batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@batch)}
    @discounts=@date.fee_discounts.all(:conditions=>"batch_id=#{@batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@batch) }
    @total_discount = 0
    @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
    @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],:order=>'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
    end
    @fine_amount=0 if @financefee.is_paid

    render :pdf => 'student_fee_receipt_pdf'

    #        respond_to do |format|
    #            format.pdf { render :layout => false }
    #        end

  end

  def update_fine_ajax
    if request.post?
      @date = @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
      @batch   = Batch.find(params[:fine][:batch_id])
      student_ids=@date.finance_fees.find(:all,:conditions=>"batch_id='#{@batch.id}'").collect(&:student_id).join(',')
      @dates = @batch.finance_fee_collections
      @student = Student.find(params[:fine][:student]) if params[:fine][:student]
      @student ||= FinanceFee.first(:conditions=>"fee_collection_id = #{@date.id}",:joins=>'INNER JOIN students ON finance_fees.student_id = students.id').student
      @prev_student = @student.previous_fee_student(@date.id,student_ids)
      @next_student = @student.next_fee_student(@date.id, student_ids)

      @financefee = @student.finance_fee_by_date @date
      @paid_fees = @financefee.finance_transactions
      unless params[:fine][:fee].to_f < 0
        @fine = (params[:fine][:fee])
      else
        @financefee.errors.add_to_base("#{t('flash24')}")
      end

      @due_date = @fee_collection.due_date

      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted = false"])
      @fee_particulars = @date.finance_fee_particulars.all(:conditions=>"batch_id=#{@batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@batch) }
      @discounts=@date.fee_discounts.all(:conditions=>"batch_id=#{@batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@batch)}

      @total_discount = 0
      @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
      @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?
      bal=(@total_payable-@total_discount).to_f
      days=(Date.today-@date.due_date.to_date).to_i
      auto_fine=@date.fine
      if days > 0 and auto_fine
        @fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],:order=>'fine_days ASC')
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
      end
      render :update do |page|
        page.replace_html "student", :partial => "student_fees_submission", :with => @fine

      end
    end
  end

  def search_logic                 #student search (fees submission)
    query = params[:query]
    if query.length>= 3
      @students_result = Student.find(:all,
        :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ",
          "#{query}%","#{query}%","#{query}%",
          "#{query}", "#{query}" ],
        :order => "batch_id asc,first_name asc") unless query == ''
    else
      @students_result = Student.find(:all,
        :conditions => ["admission_no = ? " , query],
        :order => "batch_id asc,first_name asc") unless query == ''
    end
    render :layout => false
  end

  def fees_student_dates
    @student = Student.find(params[:id])
    @dates=FinanceFeeCollection.find(:all,:joins=>"INNER JOIN fee_collection_batches on fee_collection_batches.finance_fee_collection_id=finance_fee_collections.id INNER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id",:conditions=>"finance_fees.student_id='#{@student.id}' and finance_fee_collections.is_deleted=#{false}").uniq
  end

  def fees_submission_student

    if params[:date].present?
      @student = Student.find(params[:id])
      @date = @fee_collection = FinanceFeeCollection.find(params[:date])
      @financefee = @student.finance_fee_by_date(@date)


      @due_date = @fee_collection.due_date
      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
      flash[:warning]=nil
      flash[:notice]=nil

      @paid_fees = @financefee.finance_transactions


      @fee_particulars = @date.finance_fee_particulars.all(:conditions=>"batch_id=#{@financefee.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@financefee.batch) }
      @discounts=@date.fee_discounts.all(:conditions=>"batch_id=#{@financefee.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@financefee.batch) }
      @total_discount = 0
      @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
      @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?
      bal=(@total_payable-@total_discount).to_f
      days=(Date.today-@date.due_date.to_date).to_i
      auto_fine=@date.fine
      if days > 0 and auto_fine
        @fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],:order=>'fine_days ASC')
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
      end
      @fine_amount=0 if @financefee.is_paid
      render :update do |page|
        page.replace_html "fee_submission", :partial => "fees_submission_form"
      end
    else
      render :update do |page|
        page.replace_html "fee_submission", :text=>""
      end
    end


  end

  def update_student_fine_ajax

    @student = Student.find(params[:fine][:student])
    @date = @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
    @financefee = @student.finance_fee_by_date(@date)
    unless params[:fine][:fee].to_f < 0
      @fine = (params[:fine][:fee])
      flash[:notice] = nil
    else
      flash[:notice] = "#{t('flash24')}"
    end
    @paid_fees = @financefee.finance_transactions
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @date.finance_fee_particulars.all(:conditions=>"batch_id=#{@student.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@student.batch) }
    @discounts=@date.fee_discounts.all(:conditions=>"batch_id=#{@student.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@student.batch) }
    @total_discount = 0
    @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
    @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],:order=>'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
    end
    render :update do |page|
      page.replace_html "fee_submission", :partial => "fees_submission_form"
    end

  end

  def select_payment_mode
    if  params[:payment_mode]=="#{t('others')}"
      render :update do |page|
        page.replace_html "payment_mode", :partial => "select_payment_mode"
      end
    else
      render :update do |page|
        page.replace_html "payment_mode", :text=>""
      end
    end
  end

  def fees_submission_save
    @student = Student.find(params[:student])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @date.fee_transactions(@student.id)

    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @date.finance_fee_particulars.all(:conditions=>"batch_id=#{@student.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@student.batch) }
    @discounts=@date.fee_discounts.all(:conditions=>"batch_id=#{@student.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@student.batch) }
    @total_discount = 0
    @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
    @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?
    total_fees = @financefee.balance.to_f+FedenaPrecision.set_and_modify_precision(params[:special_fine]).to_f
    unless params[:fine].nil?
      total_fees += FedenaPrecision.set_and_modify_precision(params[:fine]).to_f
    end
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],:order=>'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule and @financefee.is_paid==false
    end

    @paid_fees = @financefee.finance_transactions

    if request.post?

      unless params[:fees][:fees_paid].to_f  <= 0
        unless params[:fees][:payment_mode].blank?
          unless FedenaPrecision.set_and_modify_precision(params[:fees][:fees_paid]).to_f > FedenaPrecision.set_and_modify_precision(total_fees).to_f
            transaction = FinanceTransaction.new
            (@financefee.balance.to_f > params[:fees][:fees_paid].to_f ) ? transaction.title = "#{t('receipt_no')}. (#{t('partial')}) F#{@financefee.id}" :  transaction.title = "#{t('receipt_no')}. F#{@financefee.id}"
            transaction.category = FinanceTransactionCategory.find_by_name("Fee")
            transaction.payee = @student
            transaction.finance = @financefee
            transaction.fine_included = true  unless params[:fine].nil?
            transaction.amount = params[:fees][:fees_paid].to_f
            transaction.fine_amount = params[:fine].to_f
            if params[:special_fine] and total_fees==params[:fees][:fees_paid].to_f
              transaction.fine_amount = params[:fine].to_f+params[:special_fine].to_f
              transaction.fine_included = true
              @fine_amount=0
            end
            transaction.transaction_date = Date.today
            transaction.payment_mode = params[:fees][:payment_mode]
            transaction.payment_note = params[:fees][:payment_note]
            transaction.save
            is_paid = @financefee.balance==0 ? true : false
            @financefee.update_attributes(:is_paid=>is_paid)
            flash[:warning] = "#{t('flash14')}"
            flash[:notice]=nil
          else
            flash[:warning]=nil
            flash[:notice] = "#{t('flash19')}"
          end
        else
          flash[:warning]=nil
          flash[:notice] = "#{t('select_one_payment_mode')}"
        end
      else
        flash[:warning]=nil
        flash[:notice] = "#{t('flash23')}"
      end
    end
    render :update do |page|
      page.replace_html "fee_submission", :partial => "fees_submission_form"
    end
  end


  #fees structure ----------------------

  def fees_student_structure_search_logic # student search fees structure
    query = params[:query]
    unless query.length < 3
      @students_result = Student.find(:all,
        :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                         OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ",
          "#{query}%","#{query}%","#{query}%","#{query}", "#{query}" ],
        :order => "batch_id asc,first_name asc") unless query == ''
    else
      @students_result = Student.find(:all,
        :conditions => ["admission_no = ? " , query],
        :order => "batch_id asc,first_name asc") unless query == ''
    end
    render :layout => false
  end

  def fees_structure_dates
    @student = Student.find(params[:id])
    #@dates = @student.batch.fee_collection_dates
    @student_fees = FinanceFee.find_all_by_student_id(@student.id,:select=>'fee_collection_id')
    @student_dates = ""
    @student_fees.map{|s| @student_dates += s.fee_collection_id.to_s + ","}
    @dates = FinanceFeeCollection.find(:all,:conditions=>"FIND_IN_SET(id,\"#{@student_dates}\") and is_deleted = 0")
  end

  def fees_structure_for_student
    @student = Student.find(params[:id])
    @fee_collection = FinanceFeeCollection.find params[:date]
    @finance_fee=@student.finance_fee_by_date(@fee_collection)
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_collection.finance_fee_particulars.all(:conditions=>"batch_id=#{@finance_fee.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@finance_fee.batch) }
    @discounts=@fee_collection.fee_discounts.all(:conditions=>"batch_id=#{@finance_fee.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@finance_fee.batch) }
    @total_discount = 0
    @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
    @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?
    #@total_discount_percentage = [@batch_discounts,@student_discounts,@category_discounts].flatten.compact.map{|s| s.discount(@student)}.sum
    render :update do |page|
      page.replace_html "fees_structure" , :partial => "fees_structure"
    end
  end

  def student_fees_structure
    @student = Student.find(params[:id])
    @fee_collection = FinanceFeeCollection.find params[:id2]
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_collection.finance_fee_particulars.all(:conditions=>"batch_id=#{@student.batch_id} and is_deleted=#{false}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@student.batch) and (!par.is_deleted and par.batch_id==@student.batch_id)}

  end


  #fees defaulters-----------------------

  def fees_defaulters
    @courses = Course.active
    @batchs = []
    @dates = []
  end

  def update_batches
    @course = Course.find(params[:course_id])
    @batchs = @course.batches

    render :update do |page|
      page.replace_html "batches_list", :partial => "batches_list"
    end
  end

  def update_fees_collection_dates_defaulters
    @batch  = Batch.find(params[:batch_id])
    @dates = @batch.finance_fee_collections
    render :update do |page|
      page.replace_html "fees_collection_dates", :partial => "fees_collection_dates_defaulters"
    end
  end


  def fees_defaulters_students
    @batch   = Batch.find(params[:batch_id])
    @date = FinanceFeeCollection.find(params[:date])
    @defaulters=Student.find(:all,:joins=>"INNER JOIN finance_fees on finance_fees.student_id=students.id ",:conditions=>["finance_fees.fee_collection_id='#{@date.id}' and finance_fees.balance > 0 and finance_fees.batch_id='#{@batch.id}'"],:order=>"students.first_name ASC").uniq
    render :update do |page|
      page.replace_html "student", :partial => "student_defaulters"
    end
  end

  def fee_defaulters_pdf
    @batch   = Batch.find(params[:batch_id])
    @date = @finance_fee_collection = FinanceFeeCollection.find(params[:date])
    @defaulters=Student.find(:all,:joins=>"INNER JOIN finance_fees on finance_fees.student_id=students.id ",:conditions=>["finance_fees.fee_collection_id='#{@date.id}' and finance_fees.balance > 0 and finance_fees.batch_id='#{@batch.id}'"],:select=>["students.*,finance_fees.balance as balance"],:order=>"students.first_name ASC").uniq
    @currency_type = currency

    render :pdf => 'fee_defaulters_pdf'
  end

  def pay_fees_defaulters
    @batch=Batch.find(params[:batch_id])
    @fine = params[:fine].to_f unless params[:fine].nil?
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @date.fee_transactions(@student.id)
    @due_date = @fee_collection.due_date

    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @date.finance_fee_particulars.all(:conditions=>"batch_id=#{@batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@batch) }
    @discounts=@date.fee_discounts.all(:conditions=>"batch_id=#{@batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@batch) }
    @total_discount = 0
    @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
    @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?

    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],:order=>'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
    end
    @paid_fees = @financefee.finance_transactions

    total_fees = @financefee.balance.to_f+FedenaPrecision.set_and_modify_precision(@fine_amount).to_f

    total_fees += @fine unless @fine.nil?

    if request.post?

      unless @financefee.is_paid?
        unless params[:fees][:fees_paid].to_f <= 0
          unless params[:fees][:payment_mode].blank?
            #unless params[:fees][:fees_paid].to_f> @total_fees
            unless FedenaPrecision.set_and_modify_precision(params[:fees][:fees_paid]).to_f > FedenaPrecision.set_and_modify_precision(total_fees).to_f
              transaction = FinanceTransaction.new
              (@financefee.balance.to_f > params[:fees][:fees_paid].to_f ) ? transaction.title = "#{t('receipt_no')}. (#{t('partial')}) F#{@financefee.id}" :  transaction.title = "#{t('receipt_no')}. F#{@financefee.id}"
              transaction.category = FinanceTransactionCategory.find_by_name("Fee")
              transaction.payee = @student
              transaction.finance = @financefee
              transaction.amount = params[:fees][:fees_paid].to_f
              transaction.fine_included = true  unless @fine.nil?
              transaction.fine_amount = params[:fine].to_f


              if params[:special_fine] and total_fees==params[:fees][:fees_paid].to_f
                transaction.fine_amount = params[:fine].to_f+FedenaPrecision.set_and_modify_precision(params[:special_fine]).to_f
                transaction.fine_included = true
                @fine_amount=0
              end
              transaction.transaction_date = Date.today
              transaction.payment_mode = params[:fees][:payment_mode]
              transaction.payment_note = params[:fees][:payment_note]
              transaction.save


              is_paid =@financefee.balance==0 ? true : false
              @financefee.update_attributes(:is_paid=>is_paid)

              @paid_fees = @financefee.finance_transactions
              flash[:notice] = "#{t('flash14')}"
              redirect_to  :action => "pay_fees_defaulters",:id => @student,:date => @date,:batch_id=>@batch.id
            else
              flash[:notice] = "#{t('flash19')}"
            end
          else
            flash[:warn_notice] = "#{t('select_one_payment_mode')}"
          end
        else
          flash[:warn_notice] = "#{t('flash23')}"
        end

      end
    end
  end

  def update_defaulters_fine_ajax
    @student = Student.find(params[:fine][:student])
    @date = FinanceFeeCollection.find(params[:fine][:date])
    @financefee = @date.fee_transactions(@student.id)
    @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @date.fees_particulars(@student)
    unless params[:fine][:fee].to_f < 0
      @fine = params[:fine][:fee].to_f

      total_fees = 0
      @fee_particulars.each do |p|
        total_fees += p.amount
      end
      total_fees += @fine unless @fine.nil?
    else
      flash[:notice] = "#{t('flash24')}"
    end
    redirect_to  :action => "pay_fees_defaulters", :id=> @student.id, :date=> @date.id, :fine => @fine,:batch_id=>params[:batch_id]
  end

  def compare_report

  end

  def report_compare
    if (date_format(params[:start_date]).nil? or date_format(params[:end_date]).nil? or date_format(params[:start_date2]).nil? or date_format(params[:end_date2]).nil?)
      flash[:notice]=t('invalid_date_format')
      redirect_to :controller => "user", :action => "dashboard"
    else
      fixed_category_name
      @hr = Configuration.find_by_config_value("HR")
      @start_date = (params[:start_date]).to_date
      @end_date = (params[:end_date]).to_date
      @start_date2 = (params[:start_date2]).to_date
      @end_date2 = (params[:end_date2]).to_date
      @transactions = FinanceTransaction.find(:all,
        :order => 'transaction_date desc', :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])
      @transactions2 = FinanceTransaction.find(:all,
        :order => 'transaction_date desc', :conditions => ["transaction_date >= '#{@start_date2}' and transaction_date <= '#{@end_date2}'"])
      @other_transaction_categories = FinanceTransaction.find(:all,params[:page], :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'and category_id NOT IN (#{@fixed_cat_ids.join(",")})"],
        :order => 'transaction_date').map{|ft| ft.category}.uniq
      #    @other_transactions = FinanceTransaction.report(@start_date,@end_date,params[:page])
      @other_transaction_categories2 = FinanceTransaction.find(:all,params[:page], :conditions => ["transaction_date >= '#{@start_date2}' and transaction_date <= '#{@end_date2}'and category_id NOT IN (#{@fixed_cat_ids.join(",")})"],
        :order => 'transaction_date').map{|ft| ft.category}.uniq
      #    @transactions_fees = FinanceTransaction.total_fees(@start_date,@end_date)
      #@transactions_fees2 = FinanceTransaction.total_fees(@start_date2,@end_date2)
      #    employees = Employee.find(:all)
      #    @salary = Employee.total_employees_salary(employees, @start_date, @end_date)
      #    @salary2 = Employee.total_employees_salary(employees, @start_date2, @end_date2)
      @salary = MonthlyPayslip.total_employees_salary(@start_date, @end_date)
      @salary2 = MonthlyPayslip.total_employees_salary(@start_date2, @end_date2)
      @donations_total = FinanceTransaction.donations_triggers(@start_date,@end_date)
      @donations_total2 = FinanceTransaction.donations_triggers(@start_date2,@end_date2)
      @transactions_fees = FinanceTransaction.total_fees(@start_date,@end_date).map{|t| t.transaction_total.to_f}.sum
      @transactions_fees2 = FinanceTransaction.total_fees(@start_date2,@end_date2).map{|t| t.transaction_total.to_f}.sum
      @batchs = Batch.find(:all)
      @grand_total = FinanceTransaction.grand_total(@start_date,@end_date)
      @grand_total2 = FinanceTransaction.grand_total(@start_date2,@end_date2)
      @category_transaction_totals = {}
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        @category_transaction_totals["#{category[:category_name]}"] =   FinanceTransaction.total_transaction_amount(category[:category_name],@start_date,@end_date)
      end
      @category_transaction_totals2 = {}
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        @category_transaction_totals2["#{category[:category_name]}"] =   FinanceTransaction.total_transaction_amount(category[:category_name],@start_date2,@end_date2)
      end
      @graph = open_flash_chart_object(960, 500, "graph_for_compare_monthly_report?start_date=#{@start_date}&end_date=#{@end_date}&start_date2=#{@start_date2}&end_date2=#{@end_date2}")
    end
  end

  def month_date
    @start_date = params[:start_date]
    @end_date  = params[:end_date]
  end

  def partial_payment
    render :update do |page|
      page.replace_html "partial_payment", :partial => "partial_payment"
    end
  end


  #reports pdf---------------------------

  def pdf_fee_structure
    @student = Student.find(params[:id])
    @institution_name = Configuration.find_by_config_key("InstitutionName")
    @institution_address = Configuration.find_by_config_key("InstitutionAddress")
    @institution_phone_no = Configuration.find_by_config_key("InstitutionPhoneNo")
    @currency_type = currency
    @fee_collection = FinanceFeeCollection.find params[:id2]
    @finance_fee=@student.finance_fee_by_date(@fee_collection)
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_collection.finance_fee_particulars.all(:conditions=>"batch_id=#{@finance_fee.batch_id}").select{|par| par.receiver==@student or par.receiver==@student.student_category or par.receiver==@finance_fee.batch}
    @discounts=@fee_collection.fee_discounts.all(:conditions=>"batch_id=#{@finance_fee.batch_id}").select{|par| par.receiver==@student or par.receiver==@student.student_category or par.receiver==@finance_fee.batch}
    @total_discount = 0
    @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
    @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?

    render :pdf => 'pdf_fee_structure'

    #        respond_to do |format|
    #            format.pdf { render :layout => false }
    #        end
  end

  #graph------------------------------------


  def graph_for_update_monthly_report

    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date
    employees = Employee.find(:all)

    hr = Configuration.find_by_config_value("HR")
    donations_total = FinanceTransaction.donations_triggers(start_date,end_date)
    fees = FinanceTransaction.total_fees(start_date,end_date).map{|t| t.transaction_total.to_f}.sum
    income = FinanceTransaction.total_other_trans(start_date,end_date)[0]
    expense = FinanceTransaction.total_other_trans(start_date,end_date)[1]
    #    other_transactions = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])


    x_labels = []
    data = []
    largest_value =0

    unless hr.nil?
      salary = FinanceTransaction.sum('amount',:conditions=>{:title=>"Monthly Salary",:transaction_date=>start_date..end_date}).to_f
      unless salary <= 0
        x_labels << "#{t('salary')}"
        data << salary-(salary*2)
        largest_value = salary if largest_value < salary
      end
    end
    unless donations_total <= 0
      x_labels << "#{t('donations')}"
      data << donations_total
      largest_value = donations_total if largest_value < donations_total
    end

    unless fees <= 0
      x_labels << "#{t('fees_text')}"
      data << fees
      largest_value = fees if largest_value < fees
    end

    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      transaction = FinanceTransaction.total_transaction_amount(category[:category_name],start_date,end_date)
      amount = transaction[:amount]
      unless amount <= 0
        x_labels << "#{category[:category_name]}"
        transaction[:category_type] == "income" ? data << amount : data << amount-(amount*2)
        largest_value = amount if largest_value < amount
      end
    end

    unless income <= 0
      x_labels << "#{t('other_income')}"
      data << income
      largest_value = income if largest_value < income
    end
    unless expense <= 0
      x_labels << "#{t('other_expense')}"
      data << expense-(expense*2)
      largest_value = expense if largest_value < expense
    end


    #    other_transactions.each do |trans|
    #      x_labels << trans.title
    #      if trans.category.is_income? and trans.master_transaction_id == 0
    #        data << trans.amount
    #      else
    #        data << ("-"+trans.amount.to_s).to_i
    #      end
    #      largest_value = trans.amount if largest_value < trans.amount
    #    end

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "#{t('amount')}"
    bargraph.values = data

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(FedenaPrecision.set_and_modify_precision(largest_value-(largest_value*2)),FedenaPrecision.set_and_modify_precision(largest_value),FedenaPrecision.set_and_modify_precision(largest_value/5))

    title = Title.new("#{t('finance_transactions')}")

    x_legend = XLegend.new("Examination name")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("Marks")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis

    chart.add_element(bargraph)


    render :text => chart.render

  end
  def graph_for_compare_monthly_report

    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date
    start_date2 = (params[:start_date2]).to_date
    end_date2 = (params[:end_date2]).to_date
    employees = Employee.find(:all)

    hr = Configuration.find_by_config_value("HR")
    donations_total = FinanceTransaction.donations_triggers(start_date,end_date)
    donations_total2 = FinanceTransaction.donations_triggers(start_date2,end_date2)
    fees = FinanceTransaction.total_fees(start_date,end_date).map{|t| t.transaction_total.to_f}.sum
    fees2 = FinanceTransaction.total_fees(start_date2,end_date2).map{|t| t.transaction_total.to_f}.sum
    income = FinanceTransaction.total_other_trans(start_date,end_date)[0]
    income2 = FinanceTransaction.total_other_trans(start_date2,end_date2)[0]
    expense = FinanceTransaction.total_other_trans(start_date,end_date)[1]
    expense2 = FinanceTransaction.total_other_trans(start_date2,end_date2)[1]

    #    other_transactions = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])
    #    other_transactions2 = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date2}' and transaction_date <= '#{end_date2}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])


    x_labels = []
    data = []
    data2 = []
    largest_value =0

    unless hr.nil?
      salary = Employee.total_employees_salary(employees,start_date,end_date)
      salary2 = Employee.total_employees_salary(employees,start_date2,end_date2)
      unless salary <= 0 and salary2 <= 0
        x_labels << "#{t('salary')}"
        data << salary-(salary*2)
        data2 << salary2-(salary2*2)
        largest_value = salary if largest_value < salary
        largest_value = salary2 if largest_value < salary2
      end
    end
    unless donations_total <= 0 and donations_total2 <= 0
      x_labels << "#{t('donations')}"
      data << donations_total
      data2 << donations_total2
      largest_value = donations_total if largest_value < donations_total
      largest_value = donations_total2 if largest_value < donations_total2
    end

    unless fees <= 0 and fees2 <= 0
      x_labels << "#{t('fees_text')}"
      data << FedenaPrecision.set_and_modify_precision(fees).to_f
      data2 << FedenaPrecision.set_and_modify_precision(fees2).to_f
      largest_value = fees if largest_value < fees
      largest_value = fees2 if largest_value < fees2
    end

    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      transaction1 =   FinanceTransaction.total_transaction_amount(category[:category_name],start_date,end_date)
      transaction2 =   FinanceTransaction.total_transaction_amount(category[:category_name],start_date2,end_date2)
      amount1 = transaction1[:amount]
      amount2 = transaction2[:amount]
      unless amount1 <= 0 and amount2 <= 0
        x_labels << "#{category[:category_name]}"
        transaction1[:category_type] == "income" ? data << amount1 : data << amount1-(amount1*2)
        transaction2[:category_type] == "income" ? data2 << amount2 : data2 << amount2-(amount2*2)
        largest_value = amount1 if largest_value < amount1
        largest_value = amount2 if largest_value < amount2
      end
    end

    unless income <= 0 and income2 <= 0
      x_labels << "#{t('other_income')}"
      data << income
      data2 << income2
      largest_value = income if largest_value < income
      largest_value = income2 if largest_value < income2
    end

    unless expense <= 0 and expense2 <= 0
      x_labels << "#{t('other_expense')}"
      data << FedenaPrecision.set_and_modify_precision(expense-(expense*2)).to_f
      data2 << FedenaPrecision.set_and_modify_precision(expense2-(expense2*2)).to_f
      largest_value = expense if largest_value < expense
      largest_value = expense2 if largest_value < expense2
    end

    #       other = 0
    #    other_transactions.each do |trans|
    #
    #      if trans.category.is_income? and trans.master_transaction_id == 0
    #        other += trans.amount
    #      else
    #        other -= trans.amount
    #      end
    #    end
    #    x_labels << "other"
    #    data << other
    #    largest_value = other if largest_value < other
    #    other2 = 0
    #    other_transactions2.each do |trans2|
    #      if trans2.category.is_income?
    #        other2 += trans2.amount
    #      else
    #        other2 -= trans2.amount
    #      end
    #    end
    #    data2 << other2
    #    largest_value = other2 if largest_value < other2

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "#{t('for_the_period')} #{start_date}-#{end_date}"
    bargraph.values = data
    bargraph2 = BarFilled.new()
    bargraph2.width = 1;
    bargraph2.colour = '#000000';
    bargraph2.dot_size = 3;
    bargraph2.text = "#{t('for_the_period')} #{start_date2}-#{end_date2}"
    bargraph2.values = data2

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(FedenaPrecision.set_and_modify_precision(largest_value-(largest_value*2)),FedenaPrecision.set_and_modify_precision(largest_value),FedenaPrecision.set_and_modify_precision(largest_value/5))

    title = Title.new("#{t('finance_transactions')}")

    x_legend = XLegend.new("#{t('examination_name')}")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("#{t('marks')}")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis

    chart.add_element(bargraph)
    chart.add_element(bargraph2)


    render :text => chart.render

  end

  #ddnt complete this graph!

  def graph_for_transaction_comparison

    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date
    employees = Employee.find(:all)

    hr = Configuration.find_by_config_value("HR")
    donations_total = FinanceTransaction.donations_triggers(start_date,end_date)
    fees = FinanceTransaction.total_fees(start_date,end_date).map{|t| t.transaction_total.to_f}.sum
    income = FinanceTransaction.total_other_trans(start_date,end_date)[0]
    expense = FinanceTransaction.total_other_trans(start_date,end_date)[1]
    #    other_transactions = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])


    x_labels = []
    data1 = []
    data2 = []

    largest_value =0

    unless hr.nil?
      salary = Employee.total_employees_salary(employees,start_date,end_date)
    end
    unless salary <= 0
      x_labels << "#{t('salary')}"
      data << salary-(salary*2)
      largest_value = salary if largest_value < salary
    end
    unless donations_total <= 0
      x_labels << "#{t('donations')}"
      data << donations_total
      largest_value = donations_total if largest_value < donations_total
    end

    unless fees <= 0
      x_labels << "#{t('fees_text')}"
      data << fees
      largest_value = fees if largest_value < fees
    end

    unless income <= 0
      x_labels << "#{t('other_income')}"
      data << income
      largest_value = income if largest_value < income
    end

    unless expense <= 0
      x_labels << "#{t('other_expense')}"
      data << expense
      largest_value = expense if largest_value < expense
    end

    #    other_transactions.each do |trans|
    #      x_labels << trans.title
    #      if trans.category.is_income? and trans.master_transaction_id == 0
    #        data << trans.amount
    #      else
    #        data << ("-"+trans.amount.to_s).to_i
    #      end
    #      largest_value = trans.amount if largest_value < trans.amount
    #    end

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "#{t('amount')}"
    bargraph.values = data

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(largest_value-(largest_value*2),largest_value,largest_value/5)

    title = Title.new("#{t('finance_transactions')}")

    x_legend = XLegend.new("#{t('examination_name')}")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("#{t('marks')}")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis

    chart.add_element(bargraph)


    render :text => chart.render


  end
  #fee Discount
  def fee_discounts
    @batches = Batch.active
  end

  def fee_discount_new
    @batches = Batch.active
  end

  def load_discount_create_form
    if params[:type]== "batch_wise"
      @fee_categories =  FinanceFeeCategory.find(:all,:joins=>"INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=finance_fee_categories.id AND finance_fee_particulars.is_deleted = 0 INNER JOIN batches on batches.id=finance_fee_particulars.batch_id AND batches.is_active = 1 AND batches.is_deleted = 0 AND finance_fee_categories.is_deleted=0",:group=>'finance_fee_categories.name')
      @fee_discount = BatchFeeDiscount.new
      render :update do |page|
        page.replace_html "form-box", :partial => "batch_wise_discount_form"
        page.replace_html 'form-errors', :text =>""
      end
    elsif params[:type]== "category_wise"
      @fee_categories = FinanceFeeCategory.find(:all,:joins=>"INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=finance_fee_categories.id AND finance_fee_particulars.is_deleted = 0 INNER JOIN batches on batches.id=finance_fee_particulars.batch_id AND batches.is_active = 1 AND batches.is_deleted = 0 AND finance_fee_categories.is_deleted=0",:group=>'finance_fee_categories.name')
      @student_categories = StudentCategory.active
      render :update do |page|
        page.replace_html "form-box", :partial => "category_wise_discount_form"
        page.replace_html 'form-errors', :text =>""
      end
    elsif params[:type] == "student_wise"
      @courses = Course.active
      render :update do |page|
        page.replace_html "form-box", :partial => "student_wise_discount_form"
        page.replace_html 'form-errors', :text =>""
      end
    else
      render :update do |page|
        page.replace_html "form-box", :text => ""
        page.replace_html 'form-errors', :text =>""
      end
    end
  end

  def load_discount_batch
    if params[:id].present?
      @course = Course.find(params[:id])
      @batches =Batch.find(:all,:joins=>"INNER JOIN students on students.batch_id=batches.id",:conditions=>"batches.course_id=#{@course.id}").uniq
      #@batches = @course.batches.active
      render :update do |page|
        page.replace_html "batch-box", :partial => "fee_discount_batch_list"
      end
    else
      render :update do |page|
        page.replace_html "batch-box", :text => ""
      end
    end
  end

  def load_batch_fee_category
    if params[:batch].present?
      @batch=Batch.find(params[:batch])
      fees_categories =FinanceFeeCategory.find(:all,:joins=>"INNER JOIN category_batches on category_batches.finance_fee_category_id=finance_fee_categories.id INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=category_batches.finance_fee_category_id",
        :conditions=>"finance_fee_particulars.batch_id=#{@batch.id} and category_batches.batch_id=#{@batch.id} and finance_fee_particulars.is_deleted=false and finance_fee_categories.is_deleted=false and finance_fee_categories.is_master=1").uniq
      #fees_categories = @batch.finance_fee_categories.find(:all,:conditions=>"is_deleted = 0 and is_master = 1")
      @fees_categories=[]
      fees_categories.each do |f|
        particulars=f.fee_particulars.select{|s| s.is_deleted==false}
        unless particulars.empty?
          @fees_categories << f
        end
      end
      render :update do |page|
        page.replace_html "fee-category-box", :partial => "fee_discount_category_list"
      end
    else
      render :update do |page|
        page.replace_html "fee-category-box", :text => ""
      end
    end
  end

  def batch_wise_discount_create
    unless params[:fee_collection].blank?
      FeeDiscount.transaction do
        params[:fee_collection][:category_ids].each do |c|
          # @fee_category = FinanceFeeCategory.find(params[:category])
          @fee_discount = FeeDiscount.new(params[:fee_discount])
          # @fee_discount.finance_fee_category_id =params[:category]
          @fee_discount.receiver_type="Batch"
          @fee_discount.receiver_id = c
          @fee_discount.batch_id=c
          unless @fee_discount.save
            @error = true
            raise ActiveRecord::Rollback
          end
        end
      end
    else
      @fee_discount = BatchFeeDiscount.new(params[:fee_discount])
      @fee_discount.errors.add_to_base("#{t('fees_category_cant_be_blank')}")
      @error = true
    end
  end

  def category_wise_fee_discount_create
    unless params[:fee_collection].blank?
      FeeDiscount.transaction do
        params[:fee_collection][:category_ids].each do |c|
          #@fee_category = FinanceFeeCategory.find(c)
          @fee_discount = FeeDiscount.new(params[:fee_discount])
          #        @fee_discount.finance_fee_category_id = params[:category]
          @fee_discount.receiver_type="StudentCategory"
          @fee_discount.batch_id=c
          unless @fee_discount.save
            @error = true
            @fee_discount.errors.add_to_base("#{t('select_student_category')}") if params[:fee_discount][:receiver_id].empty?
            raise ActiveRecord::Rollback


          end
        end
      end
    else
      @fee_discount = FeeDiscount.new(params[:fee_discount])
      @fee_discount.errors.add_to_base("#{t('batch_cant_be_blank')}")
      @error = true
    end
  end

  def student_wise_fee_discount_create
    @error = false
    @fee_discount = FeeDiscount.new(params[:fee_discount])
    batch=Batch.find_by_id(params[:fee_discount][:batch_id])
    unless (params[:fee_discount][:finance_fee_category_id]).blank?
      @fee_category = FinanceFeeCategory.find(@fee_discount.finance_fee_category_id)
      unless (params[:students]).blank?
        admission_no = (params[:students]).split(",")
        admission_no.each do |a|
          s = Student.find_by_admission_no(a)
          unless s.nil?
            if FeeDiscount.find_by_type_and_receiver_id('StudentFeeDiscount',s.id,:conditions=>"finance_fee_category_id = #{@fee_category.id}").present?
              @error = true
              @fee_discount.errors.add_to_base("#{t('flash20')} - #{a}")
            end
            unless (s.batch_id == batch.id)
              @error = true
              @fee_discount.errors.add_to_base("#{a} #{t('does_not_belong_to_batch')} #{batch.full_name}")
            end
          else
            @error = true
            @fee_discount.errors.add_to_base("#{a} #{t('is_invalid_admission_no')}")
          end
        end
        unless @error
          admission_no.each do |a|
            s = Student.find_by_admission_no(a)
            @fee_discount =FeeDiscount.new(params[:fee_discount])
            @fee_discount.receiver_type="Student"
            @fee_discount.receiver_id = s.id
            @fee_discount.batch_id=s.batch_id
            unless @fee_discount.save
              @error = true
            end
          end
        end
      else
        @error = true
        @fee_discount.errors.add_to_base("#{t('admission_cant_be_blank')}")
      end
    else
      @error = true
      @fee_discount.errors.add_to_base("#{t('fees_category_cant_blank')}")
    end
  end


  def update_master_fee_category_list
    @batch = Batch.find(params[:id])
    @fee_categories=@batch.finance_fee_categories.find(:all,:conditions=>"is_master=1 and is_deleted= 0")
    #@fee_categories = FinanceFeeCategory.find_all_by_batch_id(@batch.id, :conditions=>"is_master=1 and is_deleted= 0")
    render :update do |page|
      page.replace_html "master-category-box", :partial => "update_master_fee_category_list"
    end
  end

  def show_fee_discounts
    @batch=Batch.find(params[:b_id])
    if params[:id]==""
      render :update do |page|
        page.replace_html "discount-box", :text=>""
      end
    else

      @fee_category = FinanceFeeCategory.find(params[:id])
      @discounts = @fee_category.fee_discounts.all(:conditions=>["batch_id='#{@batch.id}' and is_deleted= 0"])

      render :update do |page|
        page.replace_html "discount-box", :partial => "show_fee_discounts"
      end
    end
  end

  def edit_fee_discount
    @fee_discount = FeeDiscount.find(params[:id])
  end

  def update_fee_discount
    @fee_discount = FeeDiscount.find(params[:id])
    unless @fee_discount.update_attributes(params[:fee_discount])
      @error = true
    else
      @fee_category = @fee_discount.finance_fee_category
      @discounts = @fee_category.fee_discounts.all(:conditions=>["batch_id='#{@fee_discount.batch_id}'  and is_deleted= 0"])
      #@fee_category.is_collection_open ? @discount_edit = false : @discount_edit = true
    end
  end

  def delete_fee_discount
    @fee_discount = FeeDiscount.find(params[:id])
    #batch=@fee_discount.batch
    @fee_category = FinanceFeeCategory.find(@fee_discount.finance_fee_category_id)
    @error = true  unless @fee_discount.update_attributes(:is_deleted=>true)
    unless @fee_category.nil?
      @discounts = @fee_category.fee_discounts.all(:conditions=>["batch_id='#{@fee_discount.batch_id}' and is_deleted= #{false}"])
      #@fee_category.is_collection_open ? @discount_edit = false : @discount_edit = true
    end
    render :update do |page|
      page.replace_html "discount-box", :partial => "show_fee_discounts"
      page.replace_html "flash-notice", :text => "<p class='flash-msg'>#{t('discount_deleted_successfully')}.</p>"
    end

  end

  def collection_details_view
    @fee_collection = FinanceFeeCollection.find(params[:id])
    @particulars = @fee_collection.finance_fee_particulars.all(:conditions=>["batch_id='#{params[:batch_id]}'"])
    @total_payable=@particulars.map{|s| s.amount}.sum.to_f
    @discounts = @fee_collection.fee_discounts.all(:conditions=>["batch_id='#{params[:batch_id]}'"])
  end

  def fixed_category_name
    @cat_names = ['Fee','Salary','Donation']
    @plugin_cat = []
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      @cat_names << "#{category[:category_name]}"
      @plugin_cat << "#{category[:category_name]}"
    end
    @fixed_cat_ids = FinanceTransactionCategory.find(:all,:conditions=>{:name=>@cat_names}).collect(&:id)
  end
  def delete_transaction_fees_defaulters
    transaction_deletion
    redirect_to  :action => "pay_fees_defaulters",:id => @student,:date => @date,:batch_id=>params[:batch_id]
  end
  def delete_transaction_for_student
    transaction_deletion
    render :update do |page|
      page.replace_html "fee_submission", :partial => "fees_submission_form"
    end
  end
  def delete_transaction_by_batch
    transaction_deletion
    @batch   = Batch.find(params[:batch_id])
    student_ids=@date.finance_fees.find(:all,:conditions=>"batch_id='#{@batch.id}'").collect(&:student_id).join(',')
    @dates   = FinanceFeeCollection.find(:all)
    @fee = FinanceFee.first(:conditions=>"fee_collection_id = #{@date.id}" ,:joins=>'INNER JOIN students ON finance_fees.student_id = students.id')
    @student ||= @fee.student
    @prev_student = @student.previous_fee_student(@date.id,student_ids)
    @next_student = @student.next_fee_student(@date.id,student_ids)

    render :update do |page|
      page.replace_html "student", :partial => "student_fees_submission"
    end
  end
  def transaction_deletion
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @student.finance_fee_by_date(@date)
    @financetransaction=FinanceTransaction.find(params[:transaction_id])
    balance=@financefee.balance+(@financetransaction.amount-@financetransaction.fine_amount)
    @financefee.update_attributes(:is_paid=>false,:balance=>balance)
    FeeTransaction.destroy_all(:finance_transaction_id=>params[:transaction_id])

    if @financetransaction
      transaction_attributes=@financetransaction.attributes
      transaction_attributes.delete "id"
      transaction_attributes.delete "created_at"
      transaction_attributes.delete "updated_at"
      transaction_attributes.merge!(:user_id=>current_user.id,:collection_name=>@fee_collection.name)
      cancelled_transaction=CancelledFinanceTransaction.new(transaction_attributes)
      if @financetransaction.destroy
        cancelled_transaction.save
      end

    end
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])

    flash[:warning]=nil
    flash[:notice]=nil

    @paid_fees = @financefee.finance_transactions


    @fee_particulars = @date.finance_fee_particulars.all(:conditions=>"batch_id=#{@student.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@student.batch) and (!par.is_deleted )}
    @discounts=@date.fee_discounts.all(:conditions=>"batch_id=#{@student.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@student.batch)}
    @total_discount = 0
    @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
    @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}'"],:order=>'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
    end
  end

  def update_deleted_transactions
    @transactions =CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,:conditions=>["created_at >='#{Date.today}' and created_at <'#{Date.today+1.day}'"],:order=>'created_at desc')
  end

  def transaction_filter_by_date
    @start_date=params[:s_date]
    @end_date=params[:e_date]
    @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,
      :order => 'created_at desc', :conditions => ["created_at >= '#{@start_date}' and created_at < '#{@end_date.to_date+1.day}'"])
    render :update do |page|
      page.replace_html 'search_div', :partial=>"finance/search_by_date_deleted_transactions"
    end
  end

  def list_deleted_transactions
    @transactions =CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,:conditions=>["created_at >='#{Date.today}' and created_at <'#{Date.today+1.day}'"],:order=>'created_at desc')
    render :update do |page|
      page.replace_html 'deleted_transactions', :partial=>"finance/deleted_transactions"
    end
  end

  def search_fee_collection
    if params[:option]==t('fee_collection_name')
      @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,:order=>'created_at desc',
        :conditions => ["collection_name LIKE ?",
          "#{params[:query]}%"]) unless params[:query] == ''
    elsif params[:option]==t('date_text')
      @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,:order=>'created_at desc',
        :conditions => ["created_at LIKE ?",
          "#{params[:query]}%"]) unless params[:query] == ''
    else
      if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
        @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,:order=>'created_at desc',:joins=>'LEFT OUTER JOIN students ON students.id = payee_id LEFT OUTER JOIN employees ON employees.id = payee_id LEFT OUTER JOIN instant_fees ON instant_fees.id = finance_id' ,
          :conditions => ["students.admission_no LIKE ? OR employees.employee_number LIKE ? OR instant_fees.guest_payee LIKE ?",
            "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%"]) unless params[:query] == ''
      else
        @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,:order=>'created_at desc',:joins=>'LEFT OUTER JOIN students ON students.id = payee_id LEFT OUTER JOIN employees ON employees.id = payee_id' ,
          :conditions => ["students.admission_no LIKE ? OR employees.employee_number LIKE ?",
            "#{params[:query]}%","#{params[:query]}%"]) unless params[:query] == ''
      end
    end

    render :update do |page|
      page.replace_html 'search_div', :partial=>"finance/search_deleted_transactions"
    end
    #render :partial => "finance/search_deleted_transactions"
  end

  def transactions_advanced_search
    if (params[:search] or params[:date])


      search_attr=params[:search].delete_if { |k, v| v=="" }
      condition_attr=""
      search_attr.keys.each do |k|
        if ["collection_name","category_id"].include?(k)

          condition_attr=condition_attr+" AND cancelled_finance_transactions.#{k} LIKE ? "

        elsif ["first_name","admission_no"].include?(k)
          condition_attr=condition_attr+" AND students.#{k} LIKE ?"
        elsif ["employee_number","employee_name"].include?(k)

          k=="employee_number"? condition_attr=condition_attr+" AND employees.#{k} LIKE ?" : condition_attr=condition_attr+" AND employees.first_name LIKE ?"
        else
          condition_attr=condition_attr+" AND instant_fees.#{k} LIKE ?" if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
        end

      end
      #p condition_attr.split(' ')[1..-1].join(' ')
      unless condition_attr.empty?
        condition_attr=condition_attr.split(' ')[1..-1].join(' ')
        condition_attr="("+condition_attr+")"+" AND (cancelled_finance_transactions.created_at < ? AND cancelled_finance_transactions.created_at > ?)"
      else
        condition_attr= "(cancelled_finance_transactions.created_at < ? AND cancelled_finance_transactions.created_at > ?)"
      end
      condition_array=[]
      condition_array << condition_attr
      search_attr.values.each{|c| condition_array<< (c+"%")}
      #i=2
      condition_array<<"#{params[:date][:end_date].to_date+1.day}%"
      condition_array<<"#{params[:date][:start_date]}%"
      #params[:date].values.each{|d| i=i-1;condition_array<< (d.to_date+i.day)}
      if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
        @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,:order=>'created_at desc',:joins=>'LEFT OUTER JOIN students ON students.id = payee_id LEFT OUTER JOIN employees ON employees.id = payee_id LEFT OUTER JOIN instant_fees ON instant_fees.id = finance_id' ,
          :conditions => condition_array) unless params[:query] == ''
      else
        @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,:order=>'created_at desc',:joins=>'LEFT OUTER JOIN students ON students.id = payee_id LEFT OUTER JOIN employees ON employees.id = payee_id ' ,
          :conditions => condition_array) unless params[:query] == ''
      end
      @searched_for = ""
      search_attr.each do|k,v|
        @searched_for=@searched_for+ "<span> #{k.humanize} </span>"
        @searched_for=@searched_for+ ":" +v.humanize+" "

      end
      params[:date].each do|k,v|
        @searched_for=@searched_for+ "<span> #{k.humanize} </span>"
        @searched_for=@searched_for+ ":" +v.humanize+" "

      end
      if params[:remote]=="remote"
        render :update do |page|
          page.replace_html 'search-result', :partial=>"finance/transaction_advanced_search"
        end
      end
    end
  end


  def new_refund
    @refund_rule=RefundRule.new
    @collections=FinanceFeeCollection.find(:all,:conditions=>{:is_deleted=>false},:group=>:name)
  end


  def create_refund

    @refund_rule=RefundRule.new
    @collections=FinanceFeeCollection.find(:all,:conditions=>{:is_deleted=>false},:group=>:name)
    if request.post?
      @refund_rule.attributes=params[:refund_rule]
      @refund_rule.user=current_user
      if @refund_rule.save
        flash[:notice]="#{t('refund_rule_created')}"
        redirect_to :controller=>'finance',:action=>'create_refund'
      else
        render :create_refund
      end
    end
  end

  def refund_student_search
    query = params[:query]
    if query.length>= 3
      @students= Student.find(:all,:joins=>'INNER JOIN finance_fees ON finance_fees.student_id = students.id AND finance_fees.balance=0',
        :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ",
          "#{query}%","#{query}%","#{query}%",
          "#{query}", "#{query}" ],
        :order => "batch_id asc,first_name asc") unless query == ''
      @students=@students.uniq
    else
      @students = Student.find(:all,:joins=>'INNER JOIN finance_fees ON finance_fees.student_id = students.id AND finance_fees.balance=0',
        :conditions => ["admission_no = ? " , query],
        :order => "batch_id asc,first_name asc") unless query == ''
    end
    render :layout => false
  end

  def fees_refund_dates
    @student=Student.find(params[:id])
    @dates= FinanceFeeCollection.find(:all,:joins=>"INNER JOIN finance_fees ON finance_fees.fee_collection_id = finance_fee_collections.id AND finance_fees.student_id='#{@student.id}' AND finance_fees.balance = 0")
  end

  def fees_refund_student
    @student = Student.find(params[:id])
    if params[:date].present?
      @date = @fee_collection = FinanceFeeCollection.find(params[:date])
      @financefee = @student.finance_fee_by_date(@date)


      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])

      @paid_fees = @financefee.finance_transactions

      @refund_amount=0
      @fee_particulars = @date.finance_fee_particulars.all(:conditions=>"batch_id=#{@student.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@student.batch) }
      @discounts=@date.fee_discounts.all(:conditions=>"batch_id=#{@student.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@student.batch) }
      @total_discount = 0
      @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
      @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?
      @collection=FinanceFeeCollection.find_by_name(@date.name,:conditions=>{:is_deleted=>false})
      @refund_rule=@collection.refund_rules.find(:first,:order=>'refund_validity ASC',:conditions=>["refund_validity >=  '#{Date.today}'"])
      @fee_refund=@financefee.fee_refund
      unless @refund_rule
        #@fee_refund=@financefee.fee_refund
        @refund_rule=@fee_refund.refund_rule if @fee_refund
      end
      @refund_amount=(@total_payable-@total_discount)*(@refund_rule.refund_percentage.to_f)/100 if @refund_rule
      if request.post?
        FeeRefund.transaction do
          transaction = FinanceTransaction.new
          transaction.receipt_no="refund-#{@date.id}-#{@student.id}-#{@refund_rule.id}"
          transaction.title = "#{@refund_rule.name} &#x200E;(#{@student.first_name}) &#x200E;"
          transaction.category = FinanceTransactionCategory.find_by_name("Refund")
          transaction.payee = @student
          transaction.amount = params[:fees][:amount].to_f
          transaction.transaction_date = Date.today
          transaction.description = params[:fees][:reason]
          if transaction.save

            @fee_refund=transaction.build_fee_refund(params[:fees])
            @fee_refund.finance_fee_id=@financefee.id
            @fee_refund.user=current_user
            @fee_refund.refund_rule=@refund_rule
            unless @fee_refund.save
              raise ActiveRecord::Rollback
            end
          end
        end

        render :update do |page|

          page.replace_html "refund", :partial => "fees_refund_form"
        end

      else
        render :update do |page|
          page.replace_html "fee_submission", :partial => "fees_refund_form"
        end
      end
    else
      render :update do |page|
        page.replace_html "fee_submission", :text => ""
      end
    end
  end

  def fee_refund_student_pdf
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @student.finance_fee_by_date(@date)


    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])

    @paid_fees = @financefee.finance_transactions

    @refund_amount=0
    @fee_particulars = @date.finance_fee_particulars.all(:conditions=>"batch_id=#{@student.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@student.batch) }
    @discounts=@date.fee_discounts.all(:conditions=>"batch_id=#{@student.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==@student or par.receiver==@student.student_category or par.receiver==@student.batch) }
    @total_discount = 0
    @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
    @total_discount =@discounts.map{|d| @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)}.sum.to_f unless @discounts.nil?
    fee_refund=@financefee.fee_refund
    @refund_amount=fee_refund.amount.to_f
    @refund_percentage=fee_refund.refund_rule.refund_percentage
    render :pdf => 'fee_refund_student_pdf'
  end

  def view_refunds
    @page=0
    @current_user=current_user
    @start_date=Date.today
    @end_date=Date.today
    if @current_user.admin? or @current_user.privileges.collect(&:name).include? "FinanceControl"
      if params[:id]
        @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10,:joins=>[:finance_fee],:conditions=>["finance_fees.student_id='#{params[:id].to_i}' and fee_refunds.created_at >='#{@start_date}' and fee_refunds.created_at <'#{@end_date+1.day}'"],:order=>'created_at desc')
      else
        @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10,:conditions=>["created_at >='#{@start_date}' and created_at <'#{@end_date+1.day}'"],:order=>'created_at desc')
      end
    elsif @current_user.parent?
      @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10,:joins=>[:finance_fee],:conditions=>["finance_fees.student_id='#{@current_user.guardian_entry.ward_id}' and fee_refunds.created_at >='#{Date.today}' and fee_refunds.created_at <'#{Date.today+1.day}'"],:order=>'created_at desc')
    else
      @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10,:joins=>[:finance_fee],:conditions=>["finance_fees.student_id='#{@current_user.student_entry.id}' and fee_refunds.created_at >='#{Date.today}' and fee_refunds.created_at <'#{Date.today+1.day}'"],:order=>'created_at desc')
    end
  end

  def refund_student_view
    @page=0
    @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 5,:joins=>[:finance_transaction],:conditions=>["finance_transactions.payee_id='#{params[:id].to_i}' and finance_transactions.payee_type='Student'"],:order=>'created_at desc')
  end

  def refund_student_view_pdf
    refund_student_view
    render :pdf => 'refund_student_view_pdf'
  end

  def list_refunds
    @start_date=Date.today
    @end_date=Date.today
    @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 5,:conditions=>["created_at >='#{Date.today}' and created_at <'#{Date.today+1.day}'"],:order=>'created_at desc')
    @page=params[:page]? params[:page].to_i-1 : 0
    render :update do |page|
      page.replace_html 'search_div', :partial=>"finance/view_refunds"
    end
  end

  def refund_filter_by_date
    @start_date=params[:s_date].to_date
    @end_date=params[:e_date].to_date
    @page=params[:page]? params[:page].to_i-1 : 0
    @current_user=current_user
    if @current_user.admin?  or @current_user.privileges.collect(&:name).include? "FinanceControl"
      @refunds = FeeRefund.paginate(:page => params[:page], :per_page => 10,
        :order => 'created_at desc', :conditions => ["created_at >= '#{@start_date}' and created_at < '#{@end_date.to_date+1.day}'"])
    elsif @current_user.parent?
      @refunds = FeeRefund.paginate(:page => params[:page], :per_page => 10,:joins=>[:finance_fee],
        :order => 'created_at desc', :conditions => ["finance_fees.student_id='#{@current_user.guardian_entry.ward_id}' and created_at >= '#{@start_date}' and created_at < '#{@end_date.to_date+1.day}'"])
    else
      @refunds = FeeRefund.paginate(:page => params[:page], :per_page => 10,:joins=>[:finance_fee],
        :order => 'created_at desc', :conditions => ["finance_fees.student_id='#{@current_user.student_entry.id}' and fee_refunds.created_at >= '#{@start_date}' and fee_refunds.created_at < '#{@end_date.to_date+1.day}'"])
    end
    render :update do |page|
      page.replace_html 'search_div', :partial=>"finance/view_refunds_by_date"
    end
  end

  def search_fee_refunds
    @page=params[:page]? params[:page].to_i-1 : 0

    if params[:option]==t('student_name')
      @refunds=FeeRefund.paginate(:page => params[:page], :per_page => 10,:joins=>'INNER JOIN finance_fees on finance_fees.id=fee_refunds.finance_fee_id INNER JOIN students on students.id=finance_fees.student_id',
        :order => 'created_at desc', :conditions => ["students.first_name LIKE ?",
          "#{params[:query]}%"])
    else
      @refunds=FeeRefund.paginate(:page => params[:page], :per_page => 10,:joins=>'INNER JOIN finance_fees on finance_fees.id=fee_refunds.finance_fee_id INNER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id',
        :order => 'created_at desc', :conditions => ["finance_fee_collections.name LIKE ?",
          "#{params[:query]}%"])
    end
    render :update do |page|
      page.replace_html 'search_div', :partial=>"finance/view_refunds_by_search"
    end
  end

  def refund_search_pdf

    if params[:option]==t('student_name')
      @refunds=FeeRefund.find(:all,:joins=>'INNER JOIN finance_fees on finance_fees.id=fee_refunds.finance_fee_id INNER JOIN students on students.id=finance_fees.student_id',
        :order => 'created_at desc', :conditions => ["students.first_name LIKE ?",
          "#{params[:query]}%"])
    elsif params[:option]==t('fee_collection_name') or params[:option]=="Fee Collection Name"
      @refunds=FeeRefund.find(:all,:joins=>'INNER JOIN finance_fees on finance_fees.id=fee_refunds.finance_fee_id INNER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id',
        :order => 'created_at desc', :conditions => ["finance_fee_collections.name LIKE ?",
          "#{params[:query]}%"])
    else
      if date_format_check
        if (params[:option] or (@start_date and @end_date))
          @refunds = FeeRefund.find(:all,
            :order => 'created_at desc', :conditions => ["created_at >= '#{@start_date}' and created_at < '#{@end_date.to_date+1.day}'"])

        else
          error=true

        end
      end
    end
    if error
      flash[:notice]=t('invalid_date_format')
      redirect_to :controller => "user", :action => "dashboard"
    else
      render :pdf => 'refund_search_pdf'
    end
  end

  def generate_fine
    @fine=Fine.new
    @fine_rule=FineRule.new
    @fines=Fine.active

  end



  def fine_list
    @fine=Fine.find(params[:id])
    @fine_rules=@fine.fine_rules.order_in_fine_days
    render :update do |page|
      page.replace_html "fines" ,:partial => "list_fines"
    end
  end

  def fine_slabs_edit_or_create

    if params[:id].present?
      if params[:id]=="0"
        @fine=Fine.new
        render :update do |page|
          page.replace_html "form-errors", :text=>""
          page.replace_html "select_fine", :partial=> "new_fine"
          page.replace_html "flash_box", :text=> ""
        end
      else
        @fine=Fine.find(params[:id])
        render :update do |page|
          page.replace_html "flash_box", :text=> ""
          page.replace_html "form-errors", :text=>""
          page.replace_html "select_fine", :partial=> "list_fine_slabs"
        end
      end
    end

    if request.post?
      if params[:fine_id].nil?
        flash[:notice]=t('fine_created_successfully')
      else
        flash[:notice]=t('fine_slabs_updated')
      end
      if  params[:fine][:is_deleted].present?
        flash[:notice]=t('fine_deleted')
      end
      fine_id=params[:fine_id]
      @fine=Fine.find_or_initialize_by_id(fine_id)
      if @fine.update_attributes(params[:fine])
        # @fine=Fine.find(params[:fine_id])
        render :update do |page|
          page.redirect_to "generate_fine"
        end
      else
        flash[:notice]=nil
        render :update do |page|
          page.replace_html "form-errors", :partial=>"errors",:object=>@fine
          unless fine_id.present?
            page.replace_html "select_fine", :partial=> "fine_errors"
          else
            page.replace_html "select_fine", :partial=> "list_fine_slabs"
          end
        end
      end
    end
  end

  private

  def date_format(date)
    /(\d{4}-\d{2}-\d{2})/.match(date)
  end



end

