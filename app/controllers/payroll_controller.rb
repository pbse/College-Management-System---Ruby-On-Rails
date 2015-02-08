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

class PayrollController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  before_filter :set_precision

  def add_category
    @categories = PayrollCategory.active.find_all_by_is_deduction(false, :order=> "name ASC")
    @deductionable_categories = PayrollCategory.active.find_all_by_is_deduction(true, :order=> "name ASC")
    @category = PayrollCategory.new(params[:category])
    if request.post? and @category.save
      flash[:notice]="#{t('flash1')}"
      redirect_to :action => "add_category"
    end
    
  end

  def edit_category
    @categories = PayrollCategory.active(:all, :order=> "name ASC")
    @category = PayrollCategory.find(params[:id])
    if request.post? and @category.update_attributes(params[:category])
      flash[:notice] = "#{t('flash2')}"
      redirect_to :action => "add_category"
    end
  end

  def activate_category
    if category = PayrollCategory.update(params[:id], :status => true)
      flash[:notice1]="#{t('flash6')}"
      @categories = PayrollCategory.active.find_all_by_is_deduction(false, :order=> "name ASC")
      @deductionable_categories = PayrollCategory.active.find_all_by_is_deduction(true, :order=> "name ASC")
      render :partial => "category"
    end
  end

  def inactivate_category
    if category = PayrollCategory.update(params[:id], :status => false)
      flash[:notice1]="#{t('flash5')}"
      @categories = PayrollCategory.active.find_all_by_is_deduction(false, :order=> "name ASC")
      @deductionable_categories = PayrollCategory.active.find_all_by_is_deduction(true, :order=> "name ASC")
      render :partial => "category"
    end
  end

  def delete_category
    if params[:id]
      employees = EmployeeSalaryStructure.find(:all ,:conditions=>"payroll_category_id = #{params[:id]}")
      if employees.empty?
        payroll=PayrollCategory.find(params[:id])
        payroll.update_attributes(:is_deleted=>true)
        @departments = PayrollCategory.active
        flash[:notice]="#{t('flash3')}"
        redirect_to :action => "add_category"
      else
        flash[:warn_notice]="#{t('flash4')}"
        redirect_to :action => "add_category"
      end
    else
      redirect_to :action => "add_category"
    end
  end

  def manage_payroll
    @employee = Employee.find(params[:id])
    @independent_categories = PayrollCategory.active.find_all_by_payroll_category_id_and_status(nil, true)
    @dependent_categories = PayrollCategory.active.find_all_by_status(true, :conditions=>"payroll_category_id != \'\'")
    payroll_created = EmployeeSalaryStructure.find_all_by_employee_id(@employee.id)
    unless @independent_categories.empty? and @dependent_categories.empty?
      if payroll_created.empty?
        if request.post?
          
          params[:manage_payroll].each_pair do |k, v|
            current_amount = v['amount'].to_f
            EmployeeSalaryStructure.create(:employee_id => params[:id], :payroll_category_id => k, :amount => FedenaPrecision.set_and_modify_precision(current_amount))
          end
          flash[:notice] = "#{t('data_saved_for')} #{@employee.first_name}.  #{t('new_admission_link')} <a href='/employee/admission1'>Click Here</a>"
          redirect_to :controller => "employee", :action => "profile", :id=> @employee.id
        end
      else
        flash[:notice] = "#{t('data_saved_for')} #{@employee.first_name}.  #{t('new_admission_link')} <a href='/employee/admission1'>Click Here</a>"
        redirect_to :controller=>"employee", :action=>"profile", :id=>@employee.id
      end
    else
      flash[:notice] = "#{t('data_saved_for')} #{@employee.first_name}.  #{t('new_admission_link')} <a href='/employee/admission1'>Click Here</a>"
      redirect_to :controller=>"employee", :action=>"profile", :id=>@employee.id
    end
  end

  def update_dependent_fields
    cat_id = params[:cat_id]
    amount = params[:amount]
    @dependent_categories = PayrollCategory.active.find_all_by_payroll_category_id(cat_id,:conditions=>"status = true")
    render :update do |page|
      @dependent_categories.each do |c|
        unless c.percentage.nil?
          percentage_value = c.percentage
          calculated_amount = FedenaPrecision.set_and_modify_precision(amount.to_f*percentage_value/100)
          page["manage_payroll_#{c.id}_amount"].value = calculated_amount
          page << remote_function(:url  => {:action => "update_dependent_fields"}, :with => "'amount='+ #{calculated_amount} + '&cat_id=' + #{c.id}")
        end
      end
    end
  end
  def update_dependent_payslip_fields
    cat_id = params[:cat_id]
    amount = params[:amount]
    @dependent_categories = PayrollCategory.active.find_all_by_payroll_category_id(cat_id,:conditions=>"status = true")
    render :update do |page|
      @dependent_categories.each do |c|
        unless c.percentage.nil?
          percentage_value = c.percentage
          calculated_amount =(amount.to_i*percentage_value/100)
          page["manage_payroll_monthly_payslips_attributes_#{c.id}_amount"].value = calculated_amount
          page << remote_function(:url  => {:action => "update_dependent_fields"}, :with => "'amount='+ #{calculated_amount} + '&cat_id=' + #{c.id}")
        end
      end
    end
  end
  def edit_payroll_details
    @employee = Employee.find(params[:id])
    @independent_categories = PayrollCategory.active.find_all_by_payroll_category_id_and_status(nil, true)
    @dependent_categories = PayrollCategory.active.find_all_by_status(true, :conditions=>"payroll_category_id != \'\'")
    if request.post?
      params[:manage_payroll].each_pair do |k, v|
        current_amount = v['amount'].to_f
        row_id = EmployeeSalaryStructure.find_by_employee_id_and_payroll_category_id(@employee, k)
        unless row_id.nil?
          EmployeeSalaryStructure.update(row_id, :employee_id => params[:id], :payroll_category_id => k,
            :amount => FedenaPrecision.set_and_modify_precision(current_amount).to_f)
        else
          EmployeeSalaryStructure.create(:employee_id => params[:id], :payroll_category_id => k, :amount => '%.2f' % current_amount)
        end
        
      end
      flash[:notice] = "#{t('data_saved_for')} #{@employee.first_name}"
      redirect_to :controller => "employee", :action => "profile", :id=> @employee.id
    end
  end
end
