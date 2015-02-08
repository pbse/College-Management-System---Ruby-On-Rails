FinanceTransaction.destroy_all(:title => "Monthly Salary")
monthly_payslips=MonthlyPayslip.all(:conditions=>{:is_approved=>true},:include=>[:payroll_category])
individual_payslips=IndividualPayslipCategory.all
category_id=FinanceTransactionCategory.find_by_name('Salary').id
monthly_payslips.each do |payslip|
  if payslip.finance_transaction_id.nil?
    related_monthly_payslips=monthly_payslips.find_all_by_salary_date(payslip.salary_date).find_all_by_employee_id(payslip.employee_id)
    related_individual_payslips=individual_payslips.find_all_by_salary_date(payslip.salary_date).find_all_by_employee_id(payslip.employee_id)
    salary  = Employee.calculate_salary(related_monthly_payslips, related_individual_payslips) 
    employee = Employee.find_in_active_or_archived(payslip.employee_id)
    finance_transaction=FinanceTransaction.create(
      :title => "Monthly Salary",
      :description => "Salary of #{employee.employee_number} for the month #{I18n.l(payslip.salary_date, :format=>:month_year)}",
      :amount => salary[:net_amount],
      :category_id => category_id,
      :transaction_date => payslip.salary_date,
      :payee_type => "Employee",
      :payee_id => payslip.employee_id
    )
    related_monthly_payslips.each{|payslip| payslip.update_attribute('finance_transaction_id',finance_transaction.id) }
  end
end