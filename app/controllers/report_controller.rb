class ReportController < ApplicationController
  filter_access_to :all
  before_filter :login_required
  def index
    @course_count=Course.active.count
    @batch_count=Batch.active.count
    @student_count=Student.count
    @employee_count=Employee.count
  end

  def csv_reports
    @jobs=Delayed::Job.all.select{|j| j.payload_object.class.name=="DelayedAdditionalReportCsv"}
    @csv_report=AdditionalReportCsv.find_by_model_name_and_method_name(params[:model],params[:method])
  end

  def csv_report_download
    upload = AdditionalReportCsv.find(params[:id])
    send_file upload.csv_report.path,
      :filename => upload.csv_report_file_name,
      :type => upload.csv_report_content_type,
      :disposition => 'csv_report'
  end

  def course_batch_details
    @sort_order=params[:sort_order]
    unless @sort_order.nil?
      @courses=Course.paginate(:select=>"courses.id,courses.course_name,courses.code,courses.section_name,count(students.id) as student_count,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,count(DISTINCT IF(batches.is_deleted=0 and batches.is_active=1,batches.id,NULL)) as batch_count",:conditions=>{:courses=>{:is_deleted=>false}},:joins=>"left outer join batches on courses.id=batches.course_id left outer join students on batches.id=students.batch_id",:group=>"courses.id",:page=>params[:page],:per_page=>20,:order=>@sort_order)
    else
      @courses=Course.paginate(:select=>"courses.id,courses.course_name,courses.code,courses.section_name,count(students.id) as student_count,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,count(DISTINCT IF(batches.is_deleted=0 and batches.is_active=1,batches.id,NULL)) as batch_count",:conditions=>{:courses=>{:is_deleted=>false}},:joins=>"left outer join batches on courses.id=batches.course_id left outer join students on batches.id=students.batch_id",:group=>"courses.id",:page=>params[:page],:per_page=>20,:order=>'course_name ASC')
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "all_courses_details"
      end
    end
  end

  def course_batch_details_csv
    parameters={:sort_order=>params[:sort_order]}
    csv_export('course','course_details',parameters)
  end

  def batch_details
    @course=Course.find params[:id]
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      @batches=Batch.all(:select=>'batches.id,name,start_date,end_date,count(students.id) as student_count, count(IF(students.gender like "%m%",1,NULL)) as male_count ,count(IF(students.gender like "%f%",1,NULL)) as female_count',:joins=>"left outer join students on batches.id=students.batch_id",:conditions=>{:course_id=>params[:id],:is_active=>true,:is_deleted=>false},:group=>'batches.id',:order=>'start_date ASC')
    else
      @batches=Batch.all(:select=>'batches.id,name,start_date,end_date,count(students.id) as student_count, count(IF(students.gender like "%m%",1,NULL)) as male_count ,count(IF(students.gender like "%f%",1,NULL)) as female_count',:joins=>"left outer join students on batches.id=students.batch_id",:conditions=>{:course_id=>params[:id],:is_active=>true,:is_deleted=>false},:group=>'batches.id',:order=>@sort_order)
    end
    @employees=Employee.all(:select=>'batches.id as batch_id,employees.first_name,employees.last_name,employees.middle_name,employees.id as employee_id,employees.employee_number',:conditions=>{:batches=>{:course_id=>params[:id]}} ,:joins=>[:batches]).group_by(&:batch_id)
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "individual_batch_details"
      end
    end
  end

  def batch_details_csv
    course=Course.find params[:id]
    sort_order=params[:sort_order]
    if sort_order.nil?
      batches=Batch.all(:select=>'batches.id,name,start_date,end_date,count(students.id) as student_count, count(IF(students.gender="m",1,NULL)) as male_count ,count(IF(students.gender="f",1,NULL)) as female_count',:joins=>"left outer join students on batches.id=students.batch_id",:conditions=>{:course_id=>params[:id],:is_active=>true,:is_deleted=>false},:group=>'batches.id',:order=>'name ASC')
    else
      batches=Batch.all(:select=>'batches.id,name,start_date,end_date,count(students.id) as student_count, count(IF(students.gender="m",1,NULL)) as male_count ,count(IF(students.gender="f",1,NULL)) as female_count',:joins=>"left outer join students on batches.id=students.batch_id",:conditions=>{:course_id=>params[:id],:is_active=>true,:is_deleted=>false},:group=>'batches.id',:order=>sort_order)
    end
    employees=Employee.all(:select=>'batches.id as batch_id,employees.first_name,employees.last_name,employees.middle_name,employees.id as employee_id,employees.employee_number',:conditions=>{:batches=>{:course_id=>params[:id]}} ,:joins=>[:batches]).group_by(&:batch_id)

    csv_string=FasterCSV.generate do |csv|
      cols=["#{t('no_text')}","#{t('name')}","#{t('start_date')}","#{t('end_date')}","#{t('tutor')}","#{t('students')}","#{t('male')}","#{t('female')}"]
      csv << cols
      batches.each_with_index do |b,i|
        col=[]
        col<< "#{i+1}"
        col<< "#{b.name}"
        col<< "#{b.start_date.to_date}"
        col<< "#{b.end_date.to_date}"
        unless employees.blank?
          unless employees[b.id.to_s].nil?
            emp=[]
            employees[b.id.to_s].each do |em|
              emp << "#{em.full_name} ( #{em.employee_number} )"
            end
            col << "#{emp.join("\n")}"
          else
            col << "--"
          end
        else
          col << "--"
        end
        col<< "#{b.student_count}"
        col<< "#{b.male_count}"
        col<< "#{b.female_count}"
        col=col.flatten
        csv<< col
      end
    end
    filename = "#{course.course_name} #{t('batch')}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def batch_details_all
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      @batches=Batch.paginate(:select=>"batches.id,name,start_date,end_date,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,course_id,courses.code,count(students.id) as student_count",:joins=>"LEFT OUTER JOIN `students` ON students.batch_id = batches.id LEFT OUTER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'batches.id',:conditions=>{:is_deleted=>false,:is_active=>true},:include=>:course,:per_page=>20,:page=>params[:page],:order=>'code ASC')
    else
      @batches=Batch.paginate(:select=>"batches.id,name,start_date,end_date,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,course_id,courses.code,count(students.id) as student_count",:joins=>"LEFT OUTER JOIN `students` ON students.batch_id = batches.id LEFT OUTER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'batches.id',:conditions=>{:is_deleted=>false,:is_active=>true},:include=>:course,:per_page=>20,:page=>params[:page],:order=>@sort_order)
    end
    batch_ids=@batches.collect(&:id)
    @employees=Employee.all(:select=>'batches.id as batch_id,employees.first_name,employees.last_name,employees.middle_name,employees.id as employee_id,employees.employee_number',:joins=>[:batches],:conditions=>{:batches=>{:id=>batch_ids}}).group_by(&:batch_id)
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "batch_details_report"
      end
    end
  end

  def batch_details_all_csv
    parameters={:sort_order=>params[:sort_order]}
    csv_export('batch','batch_details',parameters)
  end

  def batch_students
    @batch=Batch.find params[:id]
    month_date=@batch.start_date.to_date
    end_date=Time.now.to_date
    config=Configuration.find_by_config_key('StudentAttendanceType')
    b_id=params[:id]
    @sort_order=params[:sort_order]
    unless config.config_value == 'Daily'
      academic_days=@batch.subject_hours(month_date, end_date, 0).values.flatten.compact.count
      unless params[:gender].present?
        if @sort_order.nil?
          @students= Student.paginate(:select=>"students.id,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{b_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id',:group=>'students.id',:conditions=>{:batch_id=>params[:id]},:per_page=>20,:page=>params[:page],:order=>'first_name ASC')
        else
          @students= Student.paginate(:select=>"students.id,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{b_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id' ,:group=>'students.id',:conditions=>{:batch_id=>params[:id]},:per_page=>20,:page=>params[:page],:order=>@sort_order)
        end
      else
        if @sort_order.nil?
          @students= Student.paginate(:select=>"students.id,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{b_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id' ,:group=>'students.id',:conditions=>["students.batch_id=? AND students.gender LIKE?",b_id,params[:gender]],:per_page=>20,:page=>params[:page],:order=>'first_name ASC')
        else
          @students= Student.paginate(:select=>"students.id,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{b_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id' ,:group=>'students.id',:conditions=>["students.batch_id=? AND students.gender LIKE?",b_id,params[:gender]],:per_page=>20,:page=>params[:page],:order=>@sort_order)
        end
      end
    else
      academic_days=@batch.academic_days.count
      unless params[:gender].present?
        if @sort_order.nil?
          @students= Student.paginate(:select=>"students.id,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{b_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{b_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{b_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id',:group=>'students.id',:conditions=>{:batch_id=>params[:id]},:per_page=>20,:page=>params[:page] ,:order=>'first_name ASC')
        else
          @students= Student.paginate(:select=>"students.id,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{b_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{b_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{b_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id',:group=>'students.id',:conditions=>{:batch_id=>params[:id]},:per_page=>20,:page=>params[:page] ,:order=>@sort_order)
        end
      else
        if @sort_order.nil?
          @students= Student.paginate(:select=>"students.id,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{b_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{b_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{b_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id',:group=>'students.id',:conditions=>["students.batch_id=? AND students.gender LIKE ?",params[:id],params[:gender]],:per_page=>20,:page=>params[:page] ,:order=>'first_name ASC')
        else
          @students= Student.paginate(:select=>"students.id,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{b_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{b_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{b_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id',:group=>'students.id',:conditions=>["students.batch_id=? AND students.gender LIKE ?",params[:id],params[:gender]],:per_page=>20,:page=>params[:page] ,:order=>@sort_order)
        end
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "batch_students_details"
      end
    end
  end

  def batch_students_csv
    parameters={:sort_order=>params[:sort_order],:batch_id=>params[:id],:gender=>params[:gender]}
    csv_export('student','batch_wise_students',parameters)
  end

  def course_students
    @course=Course.find params[:id]
    @sort_order=params[:sort_order]
    unless params[:gender].present?
      if @sort_order.nil?
        @students= Student.paginate(:select=>"students.id,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count,batches.id as batch_id",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:conditions=>{:courses=>{:id=>params[:id]}},:per_page=>20,:page=>params[:page] ,:order=>'first_name ASC')
      else
        @students= Student.paginate(:select=>"students.id,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count,batches.id as batch_id",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:conditions=>{:courses=>{:id=>params[:id]}},:per_page=>20,:page=>params[:page] ,:order=>@sort_order)
      end
    else
      if @sort_order.nil?
        @students= Student.paginate(:select=>"students.id,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count,batches.id as batch_id",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:conditions=>["courses.id=? AND students.gender LIKE ?" ,params[:id],params[:gender]],:per_page=>20,:page=>params[:page] ,:order=>'first_name ASC')
      else
        @students= Student.paginate(:select=>"students.id,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count,batches.id as batch_id",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:conditions=>["courses.id=? AND students.gender LIKE ?" ,params[:id],params[:gender]],:per_page=>20,:page=>params[:page] ,:order=>@sort_order)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "course_students_details"
      end
    end
  end

  def course_students_csv
    parameters={:sort_order=>params[:sort_order],:course_id=>params[:id],:gender=>params[:gender]}
    csv_export('student','course_wise_students',parameters)
  end

  def students_all
    @sort_order=params[:sort_order]
    if params[:subject_id].nil?
      @count=Student.all(:select=>"count(IF(students.gender Like '%m%' ,1,NULL)) as male_count, count(IF(students.gender LIKE '%f%',1,NULL)) as female_count")
      if @sort_order.nil?
        @students= Student.paginate(:select=>"first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:per_page=>20,:page=>params[:page] ,:order=>'first_name ASC')
      else
        @students= Student.paginate(:select=>"first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:per_page=>20,:page=>params[:page] ,:order=>@sort_order)
      end
    else
      @count=Student.all(:select=>"count(IF(students.gender Like '%m%' ,1,NULL)) as male_count, count(IF(students.gender LIKE '%f%',1,NULL)) as female_count",:joins=>[:students_subjects],:conditions=>["students_subjects.subject_id=? and students.batch_id=students_subjects.batch_id",params[:subject_id]])
      if @sort_order.nil?
        @students= Student.paginate(:select=>"first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id INNER JOIN `students_subjects` ON students_subjects.student_id = students.id",:group=>'students.id',:conditions=>["students_subjects.subject_id=? and students.batch_id=students_subjects.batch_id",params[:subject_id]],:per_page=>20,:page=>params[:page] ,:order=>'first_name ASC')
      else
        @students= Student.paginate(:select=>"first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id INNER JOIN `students_subjects` ON students_subjects.student_id = students.id",:group=>'students.id',:conditions=>["students_subjects.subject_id=? and students.batch_id=students_subjects.batch_id",params[:subject_id]],:per_page=>20,:page=>params[:page] ,:order=>@sort_order)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "students_all_details"
      end
    end
  end

  def students_all_csv
    parameters={:sort_order=>params[:sort_order],:subject_id=>params[:subject_id]}
    csv_export('student','students_details',parameters)
  end

  def employees
    @dpt_count=EmployeeDepartment.count(:conditions=>{:status=>true})
    @count=Employee.all(:select=>"count(IF(employees.gender Like '%m%' ,1,NULL)) as male_count, count(IF(employees.gender LIKE '%f%',1,NULL)) as female_count")
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      @employees=Employee.paginate(:select=>"employees.first_name,employees.middle_name,employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `employees`.reporting_manager_id",:per_page=>20,:page=>params[:page],:order=>'first_name ASC')
    else
      @employees=Employee.paginate(:select=>"employees.first_name,employees.middle_name,employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `employees`.reporting_manager_id",:per_page=>20,:page=>params[:page],:order=>@sort_order)
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "employees_list"
      end
    end
  end

  def employees_csv
    parameters={:sort_order=>params[:sort_order]}
    csv_export('employee','employee_details',parameters)
  end

  def former_students
    @sort_order=params[:sort_order]
    unless params[:former_students].nil?
      @count=ArchivedStudent.all(:select=>"count(IF(archived_students.gender like '%m%',1,NULL)) as male_count,count(IF(archived_students.gender LIKE '%f%',1,NULL))as female_count",:conditions=>{:archived_students=>{:created_at=>params[:former_students][:from].to_date.beginning_of_day..params[:former_students][:to].to_date.end_of_day}})
      if @sort_order.nil?
        @students=ArchivedStudent.paginate(:select=>"first_name,last_name,middle_name,admission_no,admission_date,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:created_at=>params[:former_students][:from].to_date.beginning_of_day..params[:former_students][:to].to_date.end_of_day}},:page=>params[:page],:per_page=>20,:order=>'first_name ASC')
      else
        @students=ArchivedStudent.paginate(:select=>"first_name,last_name,middle_name,admission_no,admission_date,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:created_at=>params[:former_students][:from].to_date.beginning_of_day..params[:former_students][:to].to_date.end_of_day}},:page=>params[:page],:per_page=>20,:order=>@sort_order)
      end
    else
      @count=ArchivedStudent.all(:select=>"count(IF(archived_students.gender like '%m%',1,NULL)) as male_count,count(IF(archived_students.gender LIKE '%f%',1,NULL))as female_count",:conditions=>{:archived_students=>{:created_at=> Date.today.beginning_of_day..Date.today.end_of_day}})
      if @sort_order.nil?
        @students=ArchivedStudent.paginate(:select=>"first_name,last_name,middle_name,admission_no,admission_date,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:created_at=> Date.today.beginning_of_day..Date.today.end_of_day}},:page=>params[:page],:per_page=>20,:order=>'first_name ASC')
      else
        @students=ArchivedStudent.paginate(:select=>"first_name,last_name,middle_name,admission_no,admission_date,CONCAT(courses.code,'-',batches.name) as batch_name,courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,archived_students.id as student_id,gender,archived_students.created_at",:joins=>[:batch=>:course],:conditions=>{:archived_students=>{:created_at=> Date.today.beginning_of_day..Date.today.end_of_day}},:page=>params[:page],:per_page=>20,:order=>@sort_order)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "former_students_details"
      end
    end
  end

  def former_students_csv
    parameters={:sort_order=>params[:sort_order],:former_students=>params[:former_students]}
    csv_export('archived_student','former_students_details',parameters)
  end

  def former_employees
    @sort_order=params[:sort_order]
    unless params[:former_employee].nil?
      @count=ArchivedEmployee.all(:select=>"count(IF(archived_employees.gender Like '%m%' ,1,NULL)) as male_count, count(IF(archived_employees.gender LIKE '%f%',1,NULL)) as female_count,archived_employees.created_at",:conditions=>{:archived_employees=>{:created_at=>params[:former_employee][:from].to_date.beginning_of_day..params[:former_employee][:to].to_date.end_of_day}})
      if @sort_order.nil?
        @former_employees=ArchivedEmployee.paginate(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.created_at" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:created_at=>params[:former_employee][:from].to_date.beginning_of_day..params[:former_employee][:to].to_date.end_of_day}},:per_page=>20,:page=>params[:page],:order=>'first_name ASC')
      else
        @former_employees=ArchivedEmployee.paginate(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.created_at" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:created_at=>params[:former_employee][:from].to_date.beginning_of_day..params[:former_employee][:to].to_date.end_of_day}},:per_page=>20,:page=>params[:page],:order=>@sort_order)
      end
    else
      @count=ArchivedEmployee.all(:select=>"count(IF(archived_employees.gender Like '%m%' ,1,NULL)) as male_count, count(IF(archived_employees.gender LIKE '%f%',1,NULL)) as female_count",:conditions=>{:archived_employees=>{:created_at=> Date.today.beginning_of_day..Date.today.end_of_day}})
      if @sort_order.nil?
        @former_employees=ArchivedEmployee.paginate(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.created_at" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:created_at=> Date.today.beginning_of_day..Date.today.end_of_day}},:per_page=>20,:page=>params[:page],:order=>'first_name ASC')
      else
        @former_employees=ArchivedEmployee.paginate(:select=>"archived_employees.first_name,archived_employees.middle_name,archived_employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , archived_employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name,archived_employees.created_at" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `archived_employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `archived_employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `archived_employees`.reporting_manager_id",:conditions=>{:archived_employees=>{:created_at=> Date.today.beginning_of_day..Date.today.end_of_day}},:per_page=>20,:page=>params[:page],:order=>@sort_order)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "former_employees_list"
      end
    end
  end

  def former_employees_csv
    parameters={:sort_order=>params[:sort_order],:former_employee=>params[:former_employee]}
    csv_export('archived_employee','former_employees_details',parameters)
  end

  def subject_details
    @courses=Course.all(:select=>"course_name,section_name,id",:conditions=>{:is_deleted=>false},:order=>'course_name ASC')
    @sort_order=params[:sort_order]
    if params[:subject_search].nil?
      if @sort_order.nil?
        @subjects=Subject.paginate(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:page=>params[:page],:per_page=>20,:order=>'name ASC')
      else
        @subjects=Subject.paginate(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:page=>params[:page],:per_page=>20,:order=>@sort_order)
      end
    else
      if @sort_order.nil?
        if params[:subject_search][:elective_subject]=="1" and params[:subject_search][:normal_subject]=="0"
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["batches.id IN (?) and elective_group_id != ? and subjects.is_deleted=?",params[:subject_search][:batch_ids],"",false],:page=>params[:page],:per_page=>20,:order=>'name ASC')
          else
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["elective_group_id != ? and subjects.is_deleted=? and batches.is_active=? and batches.is_deleted=?","",false,true,false],:page=>params[:page],:per_page=>20,:order=>'name ASC')
          end
        elsif params[:subject_search][:elective_subject]=="0" and params[:subject_search][:normal_subject]=="1"
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>params[:subject_search][:batch_ids]},:elective_group_id=>nil},:page=>params[:page],:per_page=>20,:order=>'name ASC')
          else
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:elective_group_id=>nil,:batches=>{:is_deleted=>false,:is_active=>true}},:page=>params[:page],:per_page=>20,:order=>'name ASC')
          end
        else
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>params[:subject_search][:batch_ids]}},:page=>params[:page],:per_page=>20,:order=>'name ASC')
          else
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:page=>params[:page],:per_page=>20,:order=>'name ASC')
          end
        end
      else
        if params[:subject_search][:elective_subject]=="1" and params[:subject_search][:normal_subject]=="0"
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["batches.id IN (?) and elective_group_id != ? and subjects.is_deleted=?",params[:subject_search][:batch_ids],"",false],:page=>params[:page],:per_page=>20,:order=>@sort_order)
          else
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["elective_group_id != ? and subjects.is_deleted=? and batches.is_active=? and batches.is_deleted=?","",false,true,false],:page=>params[:page],:per_page=>20,:order=>@sort_order)
          end
        elsif params[:subject_search][:elective_subject]=="0" and params[:subject_search][:normal_subject]=="1"
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>params[:subject_search][:batch_ids]},:elective_group_id=>nil},:page=>params[:page],:per_page=>20,:order=>@sort_order)
          else
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:elective_group_id=>nil,:batches=>{:is_deleted=>false,:is_active=>true}},:page=>params[:page],:per_page=>20,:order=>@sort_order)
          end
        else
          unless params[:subject_search][:batch_ids].nil? and params[:course][:course_id] == ""
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>params[:subject_search][:batch_ids]}},:page=>params[:page],:per_page=>20,:order=>@sort_order)
          else
            @subjects=Subject.paginate(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:page=>params[:page],:per_page=>20,:order=>@sort_order)
          end
        end
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "subject_list"
      end
    end
  end
  def list_batches
    unless params[:course_id].blank?
      @batches=Batch.all(:select=>"name,id,course_id",:conditions=>{:course_id=>params[:course_id],:is_deleted=>false,:is_active=>true} ,:order=>'name ASC')
      render :update do |page|
        page.replace_html "batch_list", :partial => "list_batches"
      end
    else
      render :update do |page|
        page.replace_html "batch_list", :text => ""
      end
    end
  end
  def subject_details_csv
    parameters={:sort_order=>params[:sort_order],:subject_search=>params[:subject_search],:course_id=>params[:course]}
    csv_export('subject','subject_details',parameters)
  end

  def employee_subject_association
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      @employees= Employee.paginate(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employees_subjects.id) as emp_sub_count,employee_number",:joins=>[:employees_subjects,:employee_department],:group=>"employees.id",:page=>params[:page],:per_page=>20 ,:order=>'first_name ASC')
      emp_ids=@employees.collect(&:id)
      @subjects=EmployeesSubject.all(:select=>"employees_subjects.employee_id ,subjects.name as subject_name, batches.name as batch_name ,courses.code" ,:conditions=>{:employee_id=>emp_ids,:subjects=>{:is_deleted=>false},:batches=>{:is_deleted=>false,:is_active=>true}},:joins=>" INNER JOIN `subjects` ON `subjects`.id = `employees_subjects`.subject_id INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:order=>'subject_name').group_by(&:employee_id)
    else
      @employees= Employee.paginate(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employees_subjects.id) as emp_sub_count,employee_number",:joins=>[:employees_subjects,:employee_department],:group=>"employees.id",:page=>params[:page],:per_page=>20 ,:order=>@sort_order)
      emp_ids=@employees.collect(&:id)
      @subjects=EmployeesSubject.all(:select=>"employees_subjects.employee_id ,subjects.name as subject_name, batches.name as batch_name ,courses.code" ,:conditions=>{:employee_id=>emp_ids,:subjects=>{:is_deleted=>false},:batches=>{:is_deleted=>false,:is_active=>true}},:joins=>" INNER JOIN `subjects` ON `subjects`.id = `employees_subjects`.subject_id INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:order=>'subject_name').group_by(&:employee_id)
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "employee_subject_details"
      end
    end
  end

  def employee_subject_association_csv
    parameters={:sort_order=>params[:sort_order]}
    csv_export('employee','employee_subject_association',parameters)
  end

  def employee_payroll_details
    @departments=EmployeeDepartment.all(:select=>"name,id",:conditions=>{:status=>true})
    @sort_order=params[:sort_order]
    if params[:department_id].nil? or params[:department_id].blank?
      if @sort_order.nil?
        @employees= Employee.paginate(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employee_salary_structures.id) as emp_sub_count,employee_number",:joins=>[:employee_salary_structures,:employee_department],:group=>"employees.id",:page=>params[:page],:per_page=>10 ,:order=>'first_name ASC')
        emp_ids=@employees.collect(&:id)
        @payroll=EmployeeSalaryStructure.all(:select=>"employee_id,amount,payroll_categories.name,payroll_categories.is_deduction",:joins=>[:payroll_category],:conditions=>["payroll_categories.status=? and employee_id IN (?)",true,emp_ids],:order=>'name ASC').group_by(&:employee_id)
      else
        @employees= Employee.paginate(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employee_salary_structures.id) as emp_sub_count,employee_number",:joins=>[:employee_salary_structures,:employee_department],:group=>"employees.id",:page=>params[:page],:per_page=>10 ,:order=>@sort_order)
        emp_ids=@employees.collect(&:id)
        @payroll=EmployeeSalaryStructure.all(:select=>"employee_id,amount,payroll_categories.name,payroll_categories.is_deduction",:joins=>[:payroll_category],:conditions=>["payroll_categories.status=? and employee_id IN (?)",true,emp_ids],:order=>'name ASC').group_by(&:employee_id)
      end
    else
      if @sort_order.nil?
        @employees= Employee.paginate(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employee_salary_structures.id) as emp_sub_count,employee_number",:joins=>[:employee_salary_structures,:employee_department],:group=>"employees.id",:conditions=>["employee_departments.id=?",params[:department_id]],:page=>params[:page],:per_page=>10 ,:order=>'first_name ASC')
        emp_ids=@employees.collect(&:id)
        @payroll=EmployeeSalaryStructure.all(:select=>"employee_id,amount,payroll_categories.name,payroll_categories.is_deduction",:joins=>[:payroll_category],:conditions=>["payroll_categories.status=? and employee_id IN (?)",true,emp_ids],:order=>'name ASC').group_by(&:employee_id)
      else
        @employees= Employee.paginate(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employee_salary_structures.id) as emp_sub_count,employee_number",:joins=>[:employee_salary_structures,:employee_department],:group=>"employees.id",:conditions=>["employee_departments.id=?",params[:department_id]],:page=>params[:page],:per_page=>10 ,:order=>@sort_order)
        emp_ids=@employees.collect(&:id)
        @payroll=EmployeeSalaryStructure.all(:select=>"employee_id,amount,payroll_categories.name,payroll_categories.is_deduction",:joins=>[:payroll_category],:conditions=>["payroll_categories.status=? and employee_id IN (?)",true,emp_ids],:order=>'name ASC').group_by(&:employee_id)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "payroll_details"
      end
    end
  end

  def employee_payroll_details_csv
    parameters={:sort_order=>params[:sort_order],:department_id=>params[:department_id]}
    csv_export('employee','employee_payroll_details',parameters)
  end

  def exam_schedule_details
    @courses=Course.all(:select=>"course_name,section_name,id",:conditions=>{:is_deleted=>false},:order=>'course_name ASC')
    @sort_order=params[:sort_order]
    if params[:batch_id].nil? or params[:batch_id][:batch_ids].blank?
      if @sort_order.nil?
        @examgroups=ExamGroup.paginate(:select=>"exam_groups.id,exam_groups.name,batches.name as batch_name,batches.id as batch_id,exam_type,courses.code",:conditions=>{:is_published=>true,:result_published=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:joins=>[:batch=>:course],:page=>params[:page],:per_page=>10,:order=>'name ASC')
        exam_group_ids=@examgroups.collect(&:id)
        @exams=Exam.all(:select=>"subjects.name,start_time,end_time,maximum_marks,minimum_marks,exam_group_id",:conditions=>{:exam_groups=>{:result_published=>false,:is_published=>true,:id=>exam_group_ids}},:joins=>[:exam_group,:subject]).group_by(&:exam_group_id)
      else
        @examgroups=ExamGroup.paginate(:select=>"exam_groups.id,exam_groups.name,batches.name as batch_name,batches.id as batch_id,exam_type,courses.code",:conditions=>{:is_published=>true,:result_published=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:joins=>[:batch=>:course],:page=>params[:page],:per_page=>10,:order=>@sort_order)
        exam_group_ids=@examgroups.collect(&:id)
        @exams=Exam.all(:select=>"subjects.name,start_time,end_time,maximum_marks,minimum_marks,exam_group_id",:conditions=>{:exam_groups=>{:result_published=>false,:is_published=>true,:id=>exam_group_ids}},:joins=>[:exam_group,:subject]).group_by(&:exam_group_id)
      end
    else
      if @sort_order.nil?
        @examgroups=ExamGroup.paginate(:select=>"exam_groups.id,exam_groups.name,batches.name as batch_name,batches.id as batch_id,exam_type,courses.code",:conditions=>{:is_published=>true,:result_published=>false,:batches=>{:id=>params[:batch_id][:batch_ids]}},:joins=>[:batch=>:course],:page=>params[:page],:per_page=>10,:order=>'name ASC')
        exam_group_ids=@examgroups.collect(&:id)
        @exams=Exam.all(:select=>"subjects.name,start_time,end_time,maximum_marks,minimum_marks,exam_group_id",:conditions=>{:exam_groups=>{:result_published=>false,:is_published=>true,:id=>exam_group_ids}},:joins=>[:exam_group,:subject]).group_by(&:exam_group_id)
      else
        @examgroups=ExamGroup.paginate(:select=>"exam_groups.id,exam_groups.name,batches.name as batch_name,batches.id as batch_id,exam_type,courses.code",:conditions=>{:is_published=>true,:result_published=>false,:batches=>{:id=>params[:batch_id][:batch_ids]}},:joins=>[:batch=>:course],:page=>params[:page],:per_page=>10,:order=>@sort_order)
        exam_group_ids=@examgroups.collect(&:id)
        @exams=Exam.all(:select=>"subjects.name,start_time,end_time,maximum_marks,minimum_marks,exam_group_id",:conditions=>{:exam_groups=>{:result_published=>false,:is_published=>true,:id=>exam_group_ids}},:joins=>[:exam_group,:subject]).group_by(&:exam_group_id)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "exam_details"
      end
    end
  end
  def batch_list
    unless params[:course_id].blank?
      @batches=Batch.all(:select=>"name,id,course_id",:conditions=>{:course_id=>params[:course_id],:is_deleted=>false,:is_active=>true} ,:order=>'name ASC')
      render :update do |page|
        if @batches.blank?
          page.replace_html "batch_lists", :text => ""
        else
          page.replace_html "batch_lists", :partial => "batch_list"
        end
      end
    else
      @batches=[]
      render :update do |page|
        page.replace_html "batch_lists", :partial => "batch_list"
      end
    end
  end

  def exam_schedule_details_csv
    parameters={:sort_order=>params[:sort_order],:batch_id=>params[:batch_id]}
    csv_export('exam_group','exam_schedule_details',parameters)
  end

  def fee_collection_details
    @courses=Course.all(:select=>"course_name,section_name,id",:conditions=>{:is_deleted=>false},:order=>'course_name ASC')
    @sort_order=params[:sort_order]
    if params[:batch_id].nil?
      if @sort_order.nil?
        @fee_collection= FinanceFeeCollection.paginate(:select=>"finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,batches.id as batch_id,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name",:joins=>"INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:conditions=>{:batches=>{:is_deleted=>false,:is_active=>true},:is_deleted=>false},:page=>params[:page],:per_page=>20,:order=>'name ASC')
      else
        @fee_collection= FinanceFeeCollection.paginate(:select=>"finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,batches.id as batch_id,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name",:joins=>"INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:conditions=>{:batches=>{:is_deleted=>false,:is_active=>true},:is_deleted=>false},:page=>params[:page],:per_page=>20,:order=>@sort_order)
      end
    else
      if @sort_order.nil?
        @fee_collection= FinanceFeeCollection.paginate(:select=>"finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,batches.id as batch_id,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name",:joins=>"INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:conditions=>{:batches=>{:is_deleted=>false,:is_active=>true,:id=>params[:batch_id][:batch_ids]},:is_deleted=>false},:page=>params[:page],:per_page=>20,:order=>'name ASC')
      else
        @fee_collection= FinanceFeeCollection.paginate(:select=>"finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,batches.id as batch_id,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name",:joins=>"INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:conditions=>{:batches=>{:is_deleted=>false,:is_active=>true,:id=>params[:batch_id][:batch_ids] },:is_deleted=>false},:page=>params[:page],:per_page=>20,:order=>@sort_order)
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "fees_collection_details"
      end
    end
  end

  def fee_collection_details_csv
    parameters={:sort_order=>params[:sort_order],:batch_id=>params[:batch_id]}
    csv_export('finance_fee_collection','fee_collection_details',parameters)
  end

  def course_fee_defaulters
    @sort_order=params[:sort_order]
    @total_amount=Course.sum("IF(finance_fee_collections.is_deleted='0' and batches.is_deleted='0' and students.id IS NOT NULL ,finance_fees.balance,NULL)",:joins=>"LEFT OUTER JOIN `batches` ON batches.course_id = courses.id LEFT OUTER JOIN `finance_fees` ON finance_fees.batch_id = batches.id LEFT OUTER JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:conditions=>{:is_deleted=>false}).to_f
    if @sort_order.nil?
      @courses=Course.paginate(:select=>"courses.id,course_name,section_name,courses.code,count(DISTINCT IF(batches.is_deleted='0',batches.id,NULL)) as batch_count,sum(IF(finance_fee_collections.is_deleted='0' and batches.is_deleted='0' and students.id IS NOT NULL,finance_fees.balance,NULL)) as balance",:joins=>"LEFT OUTER JOIN `batches` ON batches.course_id = courses.id LEFT OUTER JOIN `finance_fees` ON finance_fees.batch_id = batches.id LEFT OUTER JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:group=>"courses.id",:conditions=>{:is_deleted=>false},:per_page=>20,:page=>params[:page],:order=>"course_name ASC")
    else
      @courses=Course.paginate(:select=>"courses.id,course_name,section_name,courses.code,count(DISTINCT IF(batches.is_deleted='0',batches.id,NULL)) as batch_count,sum(IF(finance_fee_collections.is_deleted='0' and batches.is_deleted='0' and students.id IS NOT NULL,finance_fees.balance,NULL)) as balance",:joins=>"LEFT OUTER JOIN `batches` ON batches.course_id = courses.id LEFT OUTER JOIN `finance_fees` ON finance_fees.batch_id = batches.id LEFT OUTER JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:group=>"courses.id",:conditions=>{:is_deleted=>false},:per_page=>20,:page=>params[:page],:order=>@sort_order)
    end
    course_ids=@courses.collect(&:id)
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      @total_amount+=Course.sum("IF(transport_fee_collections.is_deleted='0' and batches.is_deleted='0' and transport_fees.transaction_id is NULL and transport_fees.receiver_type='Student' and students.id IS NOT NULL,transport_fees.bus_fare,NULL)",:joins=>"LEFT OUTER JOIN `batches` ON batches.course_id = courses.id LEFT OUTER JOIN transport_fee_collections on transport_fee_collections.batch_id=batches.id LEFT OUTER JOIN transport_fees on transport_fees.transport_fee_collection_id=transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:conditions=>{:is_deleted=>false}).to_f
      courses_transport=Course.all(:select=>"courses.id,sum(IF(transport_fee_collections.is_deleted='0' and batches.is_deleted='0' and transport_fees.transaction_id is NULL and transport_fees.receiver_type='Student' and students.id IS NOT NULL ,transport_fees.bus_fare,NULL)) as balance",:joins=>"LEFT OUTER JOIN `batches` ON batches.course_id = courses.id LEFT OUTER JOIN transport_fee_collections on transport_fee_collections.batch_id=batches.id LEFT OUTER JOIN transport_fees on transport_fees.transport_fee_collection_id=transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:group=>"courses.id",:conditions=>{:is_deleted=>false,:id=>course_ids})
      @courses.each do |course|
        course["balance"]=course.balance.to_f
        course_transport=courses_transport.select{|s| s.id==course.id}
        course.balance+=course_transport[0].balance.to_f
      end
    end
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      @total_amount+=Course.sum("IF(hostel_fee_collections.is_deleted='0' and batches.is_deleted='0' and  hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL,hostel_fees.rent,NULL)",:joins=>"LEFT OUTER JOIN `batches` ON batches.course_id = courses.id LEFT OUTER JOIN hostel_fee_collections on hostel_fee_collections.batch_id=batches.id LEFT OUTER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id=hostel_fee_collections.id  LEFT OUTER JOIN students on students.id=hostel_fees.student_id",:conditions=>{:is_deleted=>false}).to_f
      courses_hostel=Course.all(:select=>"courses.id,sum(IF(hostel_fee_collections.is_deleted='0' and batches.is_deleted='0' and hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL ,hostel_fees.rent,NULL)) as balance",:joins=>"LEFT OUTER JOIN `batches` ON batches.course_id = courses.id LEFT OUTER JOIN hostel_fee_collections on hostel_fee_collections.batch_id=batches.id LEFT OUTER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id=hostel_fee_collections.id LEFT OUTER JOIN students on students.id=hostel_fees.student_id",:group=>"courses.id",:conditions=>{:is_deleted=>false,:id=>course_ids})
      @courses.each do |course|
        course["balance"]=course.balance.to_f
        course_hostel=courses_hostel.select{|s| s.id==course.id}
        course.balance+=course_hostel[0].balance.to_f
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "course_fees_defaulters"
      end
    end
  end

  def course_fee_defaulters_csv
    parameters={:sort_order=>params[:sort_order]}
    csv_export('course','course_fee_defaulters',parameters)
  end

  def batch_fee_defaulters
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      @batches=Batch.all(:select=>"batches.id,batches.name,batches.start_date,batches.end_date,course_id,courses.code,sum(IF(finance_fee_collections.is_deleted='0' and students.id IS NOT NULL,finance_fees.balance,NULL)) as balance,count(DISTINCT IF(finance_fee_collections.is_deleted='0',finance_fee_collections.id,NULL)) as fee_collections_count",:joins=>"LEFT OUTER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER  JOIN `finance_fees` ON finance_fees.batch_id = batches.id LEFT OUTER  JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:conditions=>{:course_id=>params[:id],:is_deleted=>false},:group=>"batches.id",:include=>[:course],:order=>"balance DESC")
    else
      @batches=Batch.all(:select=>"batches.id,batches.name,batches.start_date,batches.end_date,course_id,courses.code,sum(IF(finance_fee_collections.is_deleted='0' and students.id IS NOT NULL,finance_fees.balance,NULL)) as balance,count(DISTINCT IF(finance_fee_collections.is_deleted='0',finance_fee_collections.id,NULL)) as fee_collections_count",:joins=>"LEFT OUTER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER  JOIN `finance_fees` ON finance_fees.batch_id = batches.id LEFT OUTER  JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:conditions=>{:course_id=>params[:id],:is_deleted=>false},:group=>"batches.id",:include=>[:course],:order=>@sort_order)
    end
    students_count= Batch.all(:select=>"batches.id,count(students.id) as s_count",:joins=>"LEFT OUTER JOIN students on students.batch_id=batches.id",:group=>"batches.id",:conditions=>{:is_deleted=>false,:course_id=>params[:id]})
    @batches.each do |batch|
      student_count=students_count.select{|s| s.id==batch.id}.first
      batch["student_count"]=student_count.s_count
    end
    @employees=Employee.all(:select=>'batches.id as batch_id,employees.first_name,employees.last_name,employees.middle_name,employees.id as employee_id,employees.employee_number',:conditions=>{:batches=>{:course_id=>params[:id]}} ,:joins=>[:batches]).group_by(&:batch_id)
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      batches_transport=Batch.all(:select=>"batches.id,batches.name,course_id,sum(IF(transport_fee_collections.is_deleted='0' and transport_fees.transaction_id is NULL and transport_fees.receiver_type='Student' and students.id IS NOT NULL,transport_fees.bus_fare,NULL)) as balance,count(DISTINCT IF(transport_fee_collections.is_deleted='0' and transport_fees.transaction_id is NULL and students.id IS NOT NULL,transport_fee_collections.id,NULL)) as fee_collections_count",:joins=>"LEFT OUTER JOIN transport_fee_collections on transport_fee_collections.batch_id=batches.id LEFT OUTER JOIN transport_fees on transport_fees.transport_fee_collection_id=transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:conditions=>{:course_id=>params[:id],:is_deleted=>false},:group=>"batches.id")
      @batches.each do |batch|
        batch["balance"]=batch.balance.to_f
        batch["fee_collections_count"]=batch.fee_collections_count.to_i
        batch_transport=batches_transport.select{|s| s.id==batch.id}
        batch.balance+=batch_transport[0].balance.to_f
        batch.fee_collections_count+=batch_transport[0].fee_collections_count.to_i
      end
    end
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      batches_hostel=Batch.all(:select=>"batches.id,course_id,sum(IF(hostel_fee_collections.is_deleted='0' and hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL ,hostel_fees.rent,NULL)) as balance,count(DISTINCT IF(hostel_fee_collections.is_deleted='0' and hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL,hostel_fee_collections.id,NULL)) as fee_collections_count",:joins=>"LEFT OUTER JOIN hostel_fee_collections on hostel_fee_collections.batch_id=batches.id LEFT OUTER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id=hostel_fee_collections.id LEFT OUTER JOIN students on students.id=hostel_fees.student_id",:conditions=>{:course_id=>params[:id],:is_deleted=>false},:group=>"batches.id")
      @batches.each do |batch|
        batch["balance"]=batch.balance.to_f
        batch["fee_collections_count"]=batch.fee_collections_count.to_i
        batch_hostel=batches_hostel.select{|s| s.id==batch.id}
        batch.balance+=batch_hostel[0].balance.to_f
        batch.fee_collections_count+=batch_hostel[0].fee_collections_count.to_i
      end
    end
    @total_amount=0.0
    @batches.each do |batch|
      @total_amount+=batch.balance.to_f
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "batch_fees_defaulters"
      end
    end
  end

  def batch_fee_defaulters_csv
    parameters={:sort_order=>params[:sort_order],:course_id=>params[:id]}
    csv_export('batch','batch_fee_defaulters',parameters)
  end

  def batch_fee_collections
    @total_amount=FinanceFeeCollection.sum("IF(students.id IS NOT NULL,finance_fees.balance,NULL)",:joins=>"LEFT OUTER JOIN `finance_fees` ON finance_fees.fee_collection_id = finance_fee_collections.id LEFT OUTER JOIN `batches` ON `batches`.id = `finance_fees`.batch_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:conditions=>{:finance_fees=>{:batch_id=>params[:id]},:is_deleted=>false}).to_f
    if FedenaPlugin.can_access_plugin?("fedena_transport") and FedenaPlugin.can_access_plugin?("fedena_hostel")
      @fee_collections = [{:finance_fee_collection => {:select=>"finance_fee_collections.id,finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,sum(IF(students.id IS NOT NULL ,finance_fees.balance,NULL)) as balance,count(IF(finance_fees.balance!='0.0' and students.id IS NOT NULL,finance_fees.id,NULL)) as students_count",:joins=>"LEFT OUTER JOIN `finance_fees` ON finance_fees.fee_collection_id = finance_fee_collections.id LEFT OUTER JOIN `batches` ON `batches`.id = `finance_fees`.batch_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:conditions=>{:finance_fees=>{:batch_id=>params[:id]},:is_deleted=>false},:group=>"id",:order=>"balance DESC"}},{:transport_fee_collection=>{:select=>"transport_fee_collections.id,name,start_date,end_date,due_date,sum(IF(transport_fees.transaction_id is NULL and receiver_type='Student' and students.id IS NOT NULL,transport_fees.bus_fare,NULL)) as balance, count(DISTINCT IF(transport_fees.transaction_id is NULL and receiver_type='Student' and students.id IS NOT NULL,transport_fees.id,NULL)) as students_count",:joins=>"INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:conditions=>{:batch_id=>params[:id],:is_deleted=>false,:transport_fees=>{:transaction_id=>nil}},:group=>"transport_fee_collections.id",:order=>"balance DESC"}},{:hostel_fee_collection => {:select=>"hostel_fee_collections.id,name,start_date,end_date,due_date,sum(IF(hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL ,hostel_fees.rent,NULL)) as balance, count(DISTINCT IF(hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL,hostel_fees.id,NULL)) as students_count",:joins=>"INNER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id LEFT OUTER JOIN students on students.id=hostel_fees.student_id",:conditions=>{:batch_id=>params[:id],:is_deleted=>false,:hostel_fees=>{:finance_transaction_id=>nil}},:group=>"hostel_fee_collections.id",:order=>"balance DESC"}}].model_paginate(:page =>params[:page],:per_page => 20)
      @total_amount+=TransportFeeCollection.sum("(IF(transport_fees.transaction_id is NULL and receiver_type='Student' and students.id IS NOT NULL,transport_fees.bus_fare,NULL))",:joins=>"INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:conditions=>{:batch_id=>params[:id],:is_deleted=>false,:transport_fees=>{:transaction_id=>nil}}).to_f + HostelFeeCollection.sum("(IF(hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL ,hostel_fees.rent,NULL))",:joins=>"INNER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id LEFT OUTER JOIN students on students.id=hostel_fees.student_id",:conditions=>{:batch_id=>params[:id],:is_deleted=>false,:hostel_fees=>{:finance_transaction_id=>nil}}).to_f
    elsif FedenaPlugin.can_access_plugin?("fedena_hostel")
      @fee_collections = [{:finance_fee_collection => {:select=>"finance_fee_collections.id,finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,sum(IF(students.id IS NOT NULL ,finance_fees.balance,NULL)) as balance,count(IF(finance_fees.balance!='0.0' and students.id IS NOT NULL,finance_fees.id,NULL)) as students_count",:joins=>"LEFT OUTER JOIN `finance_fees` ON finance_fees.fee_collection_id = finance_fee_collections.id LEFT OUTER JOIN `batches` ON `batches`.id = `finance_fees`.batch_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:conditions=>{:finance_fees=>{:batch_id=>params[:id]},:is_deleted=>false},:group=>"id",:order=>"balance DESC"}},{:hostel_fee_collection => {:select=>"hostel_fee_collections.id,name,start_date,end_date,due_date,sum(IF(hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL ,hostel_fees.rent,NULL)) as balance, count(DISTINCT IF(hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL,hostel_fees.id,NULL)) as students_count",:joins=>"INNER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id LEFT OUTER JOIN students on students.id=hostel_fees.student_id",:conditions=>{:batch_id=>params[:id],:is_deleted=>false,:hostel_fees=>{:finance_transaction_id=>nil}},:group=>"hostel_fee_collections.id",:order=>"balance DESC"}}].model_paginate(:page =>params[:page],:per_page => 20)
      @total_amount+=HostelFeeCollection.sum("(IF(hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL ,hostel_fees.rent,NULL))",:joins=>"INNER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id LEFT OUTER JOIN students on students.id=hostel_fees.student_id",:conditions=>{:batch_id=>params[:id],:is_deleted=>false,:hostel_fees=>{:finance_transaction_id=>nil}}).to_f
    elsif FedenaPlugin.can_access_plugin?("fedena_transport")
      @fee_collections = [{:finance_fee_collection => {:select=>"finance_fee_collections.id,finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,sum(IF(students.id IS NOT NULL ,finance_fees.balance,NULL)) as balance,count(IF(finance_fees.balance!='0.0' and students.id IS NOT NULL,finance_fees.id,NULL)) as students_count",:joins=>"LEFT OUTER JOIN `finance_fees` ON finance_fees.fee_collection_id = finance_fee_collections.id LEFT OUTER JOIN `batches` ON `batches`.id = `finance_fees`.batch_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:conditions=>{:finance_fees=>{:batch_id=>params[:id]},:is_deleted=>false},:group=>"id",:order=>"balance DESC"}},{:transport_fee_collection=>{:select=>"transport_fee_collections.id,name,start_date,end_date,due_date,sum(IF(transport_fees.transaction_id is NULL and receiver_type='Student' and students.id IS NOT NULL,transport_fees.bus_fare,NULL)) as balance, count(DISTINCT IF(transport_fees.transaction_id is NULL and receiver_type='Student' and students.id IS NOT NULL,transport_fees.id,NULL)) as students_count",:joins=>"INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:conditions=>{:batch_id=>params[:id],:is_deleted=>false,:transport_fees=>{:transaction_id=>nil}},:group=>"transport_fee_collections.id",:order=>"balance DESC"}}].model_paginate(:page =>params[:page],:per_page => 20)
      @total_amount+=TransportFeeCollection.sum("(IF(transport_fees.transaction_id is NULL and receiver_type='Student' and students.id IS NOT NULL,transport_fees.bus_fare,NULL))",:joins=>"INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:conditions=>{:batch_id=>params[:id],:is_deleted=>false,:transport_fees=>{:transaction_id=>nil}}).to_f
    else
      @fee_collections= FinanceFeeCollection.paginate(:select=>"finance_fee_collections.id,finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,sum(IF(students.id IS NOT NULL ,finance_fees.balance,NULL)) as balance,count(IF(finance_fees.balance!='0.0'and students.id IS NOT NULL,finance_fees.id,NULL)) as students_count",:joins=>"LEFT OUTER JOIN `finance_fees` ON finance_fees.fee_collection_id = finance_fee_collections.id LEFT OUTER JOIN `batches` ON `batches`.id = `finance_fees`.batch_id LEFT OUTER JOIN students on students.id=finance_fees.student_id",:conditions=>{:finance_fees=>{:batch_id=>params[:id]},:is_deleted=>false},:group=>"id",:per_page=>20,:page=>params[:page],:order=>"balance DESC")
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "batch_fees_collections"
      end
    end
  end

  def batch_fee_collections_csv
    parameters={:batch_id=>params[:id]}
    csv_export('finance_fee_collection','batch_fee_collections',parameters)
  end

  def students_fee_defaulters
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      if params[:transaction_class]=="HostelFeeCollection"
        @students=Student.paginate(:select=>"students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,rent as balance",:joins=>[:hostel_fees] ,:conditions=>["hostel_fees.hostel_fee_collection_id=? and hostel_fees.finance_transaction_id is NULL",params[:collection_id]],:per_page=>20,:page=>params[:page],:order=>"balance DESC")
        @total_amount=Student.sum("rent",:joins=>[:hostel_fees] ,:conditions=>["hostel_fees.hostel_fee_collection_id=? and hostel_fees.finance_transaction_id is NULL",params[:collection_id]])
      elsif params[:transaction_class]=="TransportFeeCollection"
        @students=Student.paginate(:select=>"students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,bus_fare as balance",:joins=>"INNER JOIN transport_fees on transport_fees.receiver_id=students.id" ,:conditions=>["transport_fees.transport_fee_collection_id=? and transport_fees.transaction_id is NULL",params[:collection_id]],:per_page=>20,:page=>params[:page],:order=>"balance DESC")
        @total_amount=Student.sum("bus_fare",:joins=>"INNER JOIN transport_fees on transport_fees.receiver_id=students.id" ,:conditions=>["transport_fees.transport_fee_collection_id=? and transport_fees.transaction_id is NULL",params[:collection_id]])
      else
        @students=Student.paginate(:select=>"students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance",:joins=>[:finance_fees] ,:conditions=>["finance_fees.fee_collection_id=? and finance_fees.balance !=? and finance_fees.batch_id=?",params[:collection_id],0.0,params[:id]],:per_page=>20,:page=>params[:page],:order=>"balance DESC")
        @total_amount=Student.sum("balance",:joins=>[:finance_fees] ,:conditions=>["finance_fees.fee_collection_id=? and finance_fees.balance !=? and finance_fees.batch_id=?",params[:collection_id],0.0,params[:id]])
      end
    else
      if params[:transaction_class]=="HostelFeeCollection"
        @students=Student.paginate(:select=>"students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,rent as balance",:joins=>[:hostel_fees] ,:conditions=>["hostel_fees.hostel_fee_collection_id=? and hostel_fees.finance_transaction_id is NULL",params[:collection_id]],:per_page=>20,:page=>params[:id],:order=>@sort_order)
        @total_amount=Student.sum("rent",:joins=>[:hostel_fees] ,:conditions=>["hostel_fees.hostel_fee_collection_id=? and hostel_fees.finance_transaction_id is NULL",params[:id]])
      elsif params[:transaction_class]=="TransportFeeCollection"
        @students=Student.paginate(:select=>"students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,bus_fare as balance",:joins=>"INNER JOIN transport_fees on transport_fees.receiver_id=students.id" ,:conditions=>["transport_fees.transport_fee_collection_id=? and transport_fees.transaction_id is NULL",params[:collection_id]],:per_page=>20,:page=>params[:od],:order=>@sort_order)
        @total_amount=Student.sum("bus_fare",:joins=>"INNER JOIN transport_fees on transport_fees.receiver_id=students.id" ,:conditions=>["transport_fees.transport_fee_collection_id=? and transport_fees.transaction_id is NULL",params[:collection_id]])
      else
        @students=Student.paginate(:select=>"students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance",:joins=>[:finance_fees] ,:conditions=>["finance_fees.fee_collection_id=? and finance_fees.balance !=? and finance_fees.batch_id=?",params[:collection_id],0.0,params[:id]],:per_page=>20,:page=>params[:page],:order=>@sort_order)
        @total_amount=Student.sum("balance",:joins=>[:finance_fees] ,:conditions=>["finance_fees.fee_collection_id=? and finance_fees.balance !=? and finance_fees.batch_id=?",params[:collection_id],0.0,params[:id]])
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "students_fees_defaulters"
      end
    end
  end

  def students_fee_defaulters_csv
    parameters={:sort_order=>params[:sort_order],:fee_collection_id=>params[:collection_id],:batch_id=>params[:id],:transaction_class=>params[:transaction_class]}
    csv_export('student','students_fee_defaulters',parameters)
  end

  def student_wise_fee_defaulters
    @total_amount=Student.sum("(IF(finance_fee_collections.is_deleted='0',finance_fees.balance,NULL))",:joins=>"LEFT OUTER JOIN finance_fees on finance_fees.student_id=students.id LEFT OUTER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id").to_f
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      @students=Student.paginate(:select=>"students.id as student_id,first_name,middle_name,last_name,admission_no,batches.name as batch_name,students.batch_id,courses.code,courses.course_name,courses.section_name,courses.id as course_id,sum(IF(finance_fee_collections.is_deleted='0',finance_fees.balance,NULL)) as balance,count(DISTINCT IF(finance_fee_collections.is_deleted='0',finance_fee_collections.id,NULL)) as fee_collections_count",:joins=>"LEFT OUTER JOIN finance_fees on finance_fees.student_id=students.id LEFT OUTER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id INNER JOIN batches on batches.id=students.batch_id INNER JOIN courses on courses.id=batches.course_id",:group=>"students.id",:per_page=>20,:page=>params[:page],:order=>"first_name")
    else
      @students=Student.paginate(:select=>"students.id as student_id,first_name,middle_name,last_name,admission_no,batches.name as batch_name,students.batch_id,courses.code,courses.course_name,courses.section_name,courses.id as course_id,sum(IF(finance_fee_collections.is_deleted='0',finance_fees.balance,NULL)) as balance,count(DISTINCT IF(finance_fee_collections.is_deleted='0',finance_fee_collections.id,NULL)) as fee_collections_count",:joins=>"LEFT OUTER JOIN finance_fees on finance_fees.student_id=students.id LEFT OUTER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id INNER JOIN batches on batches.id=students.batch_id INNER JOIN courses on courses.id=batches.course_id",:group=>"students.id",:per_page=>20,:page=>params[:page],:order=>@sort_order)
    end
    students_id=@students.collect(&:student_id)
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      @total_amount+= Student.sum("(IF(hostel_fee_collections.is_deleted='0' and hostel_fees.finance_transaction_id is NULL,hostel_fees.rent,NULL))",:joins=>"LEFT OUTER JOIN hostel_fees on hostel_fees.student_id=students.id LEFT OUTER JOIN hostel_fee_collections on hostel_fee_collections.id=hostel_fees.hostel_fee_collection_id").to_f
      students_fees_hostel=Student.all(:select=>"students.id,count(IF(hostel_fee_collections.is_deleted='0' and hostel_fees.finance_transaction_id is NULL,hostel_fees.rent,NULL)) as fee_collections_count, sum(IF(hostel_fee_collections.is_deleted='0' and hostel_fees.finance_transaction_id is NULL,hostel_fees.rent,NULL)) as balance",:joins=>"LEFT OUTER JOIN hostel_fees on hostel_fees.student_id=students.id LEFT OUTER JOIN hostel_fee_collections on hostel_fee_collections.id=hostel_fees.hostel_fee_collection_id",:group=>"students.id",:conditions=>{:id=>students_id} )
      @students.each do |student|
        student["balance"]=student.balance.to_f
        student["fee_collections_count"]=student.fee_collections_count.to_i
        student_fees_hostel=students_fees_hostel.select{|s| s.id==student.student_id.to_i}
        student.balance+=student_fees_hostel[0].balance.to_f
        student.fee_collections_count+=student_fees_hostel[0].fee_collections_count.to_i
      end
    end
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      @total_amount+=Student.sum("(IF(transport_fee_collections.is_deleted='0' and transport_fees.transaction_id is NULL and transport_fees.receiver_type='Student',transport_fees.bus_fare,NULL))",:joins=>"LEFT OUTER JOIN transport_fees on transport_fees.receiver_id=students.id LEFT OUTER JOIN transport_fee_collections on transport_fee_collections.id=transport_fees.transport_fee_collection_id").to_f
      students_fees_transport=Student.all(:select=>"students.id,count(IF(transport_fee_collections.is_deleted='0' and transport_fees.transaction_id is NULL and receiver_type='Student',transport_fee_collections.id,NULL)) as fee_collections_count,sum(IF(transport_fee_collections.is_deleted='0' and transport_fees.transaction_id is NULL and transport_fees.receiver_type='Student',transport_fees.bus_fare,NULL)) as balance",:joins=>"LEFT OUTER JOIN transport_fees on transport_fees.receiver_id=students.id LEFT OUTER JOIN transport_fee_collections on transport_fee_collections.id=transport_fees.transport_fee_collection_id",:group=>"students.id",:conditions=>{:id=>students_id})
      @students.each do |student|
        student["balance"]=student.balance.to_f
        student["fee_collections_count"]=student.fee_collections_count.to_i
        student_fees_transport=students_fees_transport.select{|s| s.id==student.student_id.to_i}
        student.balance+=student_fees_transport[0].balance.to_f
        student.fee_collections_count+=student_fees_transport[0].fee_collections_count.to_i
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "student_wise_fees_defaulters"
      end
    end
  end

  def student_wise_fee_defaulters_csv
    parameters={:sort_order=>params[:sort_order]}
    csv_export('student','students_wise_fee_defaulters',parameters)
  end

  def student_wise_fee_collections
    @student=Student.find params[:id]
    @total_amount=FinanceFeeCollection.sum("balance",:joins=>"LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id INNER JOIN students on students.id=finance_fees.student_id",:conditions=>["students.id=? and finance_fee_collections.is_deleted=?",params[:id],false]).to_f
    if FedenaPlugin.can_access_plugin?("fedena_hostel") and FedenaPlugin.can_access_plugin?("fedena_transport")
      @total_amount+=HostelFeeCollection.sum("hostel_fees.rent",:joins=>[:hostel_fees],:conditions=>{:is_deleted=>false,:hostel_fees=>{:student_id=>params[:id],:finance_transaction_id=>nil}}).to_f
      @total_amount+=TransportFeeCollection.sum("transport_fees.bus_fare",:joins=>"INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id",:conditions=>{:is_deleted=>false,:transport_fees=>{:transaction_id=>nil,:receiver_id=>params[:id],:receiver_type=>"Student"}}).to_f
      @fee_collections = [{:finance_fee_collection => {:select=>"finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,balance",:joins=>"LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id INNER JOIN students on students.id=finance_fees.student_id",:conditions=>["students.id=? and finance_fee_collections.is_deleted=?",params[:id],false],:order=>'balance DESC'}},{:hostel_fee_collection=>{:select=>"name,start_date,end_date,due_date,hostel_fees.rent as balance",:joins=>[:hostel_fees],:conditions=>{:is_deleted=>false,:hostel_fees=>{:finance_transaction_id=>nil,:student_id=>params[:id]}},:order=>"balance DESC"}},{:transport_fee_collection=>{:select=>"transport_fee_collections.id,name,start_date,end_date,due_date,transport_fees.bus_fare as balance",:joins=>"INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id",:conditions=>{:is_deleted=>false,:transport_fees=>{:transaction_id=>nil,:receiver_id=>params[:id],:receiver_type=>"Student"}},:order=>"balance DESC"}}].model_paginate(:page =>params[:page],:per_page => 20)
    elsif FedenaPlugin.can_access_plugin?("fedena_hostel")
      @total_amount+=HostelFeeCollection.sum("hostel_fees.rent",:joins=>[:hostel_fees],:conditions=>{:is_deleted=>false,:hostel_fees=>{:student_id=>params[:id],:finance_transaction_id=>nil}}).to_f
      @fee_collections = [{:finance_fee_collection => {:select=>"finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,balance",:joins=>"LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id INNER JOIN students on students.id=finance_fees.student_id",:conditions=>["students.id=? and finance_fee_collections.is_deleted=?",params[:id],false],:order=>'balance DESC'}},{:hostel_fee_collection=>{:select=>"name,start_date,end_date,due_date,hostel_fees.rent as balance",:joins=>[:hostel_fees],:conditions=>{:is_deleted=>false,:hostel_fees=>{:finance_transaction_id=>nil,:student_id=>params[:id]}},:order=>"balance DESC"}}].model_paginate(:page =>params[:page],:per_page => 20)
    elsif FedenaPlugin.can_access_plugin?("fedena_transport")
      @total_amount+=TransportFeeCollection.sum("transport_fees.bus_fare",:joins=>"INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id",:conditions=>{:is_deleted=>false,:transport_fees=>{:transaction_id=>nil,:receiver_id=>params[:id],:receiver_type=>"Student"}}).to_f
      @fee_collections = [{:finance_fee_collection => {:select=>"finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,balance",:joins=>"LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id INNER JOIN students on students.id=finance_fees.student_id",:conditions=>["students.id=? and finance_fee_collections.is_deleted=?",params[:id],false],:order=>'balance DESC'}},{:transport_fee_collection=>{:select=>"transport_fee_collections.id,name,start_date,end_date,due_date,transport_fees.bus_fare as balance",:joins=>"INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id",:conditions=>{:is_deleted=>false,:transport_fees=>{:transaction_id=>nil,:receiver_id=>params[:id]},:receiver_type=>"Student"},:order=>"balance DESC"}}].model_paginate(:page =>params[:page],:per_page => 20)
    else
      @fee_collections=FinanceFeeCollection.paginate(:select=>"finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,balance",:joins=>"LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id INNER JOIN students on students.id=finance_fees.student_id",:conditions=>["students.id=? and finance_fee_collections.is_deleted=?",params[:id],false],:page=>params[:page],:per_page=>20,:order=>'balance DESC')
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "student_wise_fees_collections"
      end
    end
  end

  def student_wise_fee_collections_csv
    parameters={:student_id=>params[:id]}
    csv_export('student','student_wise_fee_collections',parameters)
  end

end

private

def csv_export(model,method,parameters)
  csv_report=AdditionalReportCsv.find_by_model_name_and_method_name(model,method)
  if csv_report.nil?
    csv_report=AdditionalReportCsv.new(:model_name=>model,:method_name=>method,:parameters=>parameters)
    if csv_report.save
      Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id))
    end
  else
    if csv_report.update_attributes(:parameters=>parameters,:csv_report=>nil)
      Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id))
    end
  end
  flash[:notice]="#{t('csv_report_is_in_queue')}"
  redirect_to :action=>:csv_reports,:model=>model,:method=>method
end