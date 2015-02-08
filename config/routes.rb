ActionController::Routing::Routes.draw do |map|

  map.resources :grading_levels
  map.resources :ranking_levels, :collection => {:create_ranking_level=>[:get,:post], :edit_ranking_level=>[:get,:post], :update_ranking_level=>[:get,:post], :delete_ranking_level=>[:get,:post], :ranking_level_cancel=>[:get,:post], :change_priority=>[:get,:post]}
  map.resources :class_designations
  map.resources :class_timings, :except => [:index, :show]
  map.resources :class_timing_sets,
    :member => {:new_class_timings => [:post],:create_class_timings => [:post],:edit_class_timings => [:post],:update_class_timings => [:post],:delete_class_timings => [:post,:delete]},
    :collection => {:new_batch_class_timing_set => [:get],:list_batches => [:post],:add_batch => [:post]}
  map.resources :subjects
  map.resources :attendances, :collection=>{:daily_register=>:get,:subject_wise_register=>:get}
  map.resources :employee_attendances
  map.resources :attendance_reports,:collection=>{:report_pdf=>[:get],:filter_report_pdf=>[:get]}
  map.resources :cce_exam_categories
  map.resources :assessment_scores,:collection=>{:exam_fa_groups=>[:get],:observation_groups=>[:get]}
  map.resources :cce_settings,:collection=>{:basic=>[:get],:scholastic=>[:get],:co_scholastic=>[:get]}
  map.resources :scheduled_jobs,:except => [:show]
  map.resources :fa_groups,:collection=>{:assign_fa_groups=>[:get,:post],:new_fa_criteria=>[:get,:post],:create_fa_criteria=>[:get,:post],:edit_fa_criteria=>[:get,:post],:update_fa_criteria=>[:get,:post],:destroy_fa_criteria=>[:post],:reorder=>[:get,:post]}

  map.resources :fa_criterias do |fa|
    fa.resources :descriptive_indicators
  end
  map.resources :observations do |obs|
    obs.resources :descriptive_indicators
  end
  map.resources :observation_groups,:member=>{:new_observation=>[:get,:post],:create_observation=>[:get,:post],:edit_observation=>[:get,:post],:update_observation=>[:get,:post],:destroy_observation=>[:post],:reorder=>[:get,:post]},:collection=>{:assign_courses=>[:get,:post],:set_observation_group=>[:get,:post]}
  map.resources :cce_weightages,:member=>{:assign_courses=>[:get,:post]},:collection=>{:assign_weightages=>[:get,:post]}
  map.resources :cce_grade_sets, :member=>{:new_grade=>[:get,:post],:edit_grade=>[:get,:post],:update_grade=>[:get,:post],:destroy_grade=>[:post]}

  map.feed 'courses/manage_course', :controller => 'courses' ,:action=>'manage_course'
  map.feed 'courses/manage_batches', :controller => 'courses' ,:action=>'manage_batches'
  map.resources :courses, :collection => {:grouped_batches=>[:get,:post],:create_batch_group=>[:get,:post],:edit_batch_group=>[:get,:post],:update_batch_group=>[:get,:post],:delete_batch_group=>[:get,:post],:assign_subject_amount => [:get,:post],:edit_subject_amount => [:get,:post],:destroy_subject_amount => [:get,:post]} do |course|
    course.resources :batches, :except=>[:index]
  end

  map.resources :batches,:only => [], :collection=>{:batches_ajax=>[:get]} do |batch|
    batch.resources :exam_groups
    batch.resources :elective_groups, :as => :electives, :member => {:new_elective_subject => [:get, :post], :create_elective_subject => [:get,:post], :edit_elective_subject => [:get, :post, :put], :update_elective_subject => [:get, :post, :put]}
  end
  
  map.resources :single_access_tokens
  map.resources :exam_groups do |exam_group|
    exam_group.resources :exams, :member => { :save_scores => :post }
  end

  map.root :controller => 'user', :action => 'login'

  map.fa_scores 'assessment_scores/exam/:exam_id/fa_group/:fa_group_id', :controller=>'assessment_scores',:action=>'fa_scores'
  map.observation_scores 'assessment_scores/batch/:batch_id/observation_group/:observation_group_id', :controller=>'assessment_scores',:action=>'observation_scores'
  map.scheduled_task 'scheduled_jobs/:job_object/:job_type',:controller => "scheduled_jobs",:action => "index"
  map.scheduled_task_object 'scheduled_jobs/:job_object',:controller => "scheduled_jobs",:action => "index"

  map.namespace(:api) do |api|
    api.resources :attendances
    api.resources :employee_attendances
    api.resources :courses
    api.resources :batches
    api.resources :schools
    api.resources :students,:member => {:fee_dues => :get,:upload_photo => [:post]},:collection => {:fee_dues_profile => :get,:attendance_profile => :get,:exam_report_profile => :get,:student_structure => :get}
    api.resources :employees,:member => {:upload_photo => [:post]},:collection => {:leave_profile => :get,:employee_structure => :get}
    api.resources :employee_departments
    api.resources :finance_transactions
    api.resources :users
    api.resources :news
    api.resources :reminders
    api.resources :subjects
    api.resources :student_categories
    api.resources :events
    api.resources :employee_leave_types
    api.resources :payroll_categories
    api.resources :timetables
    api.resources :exam_groups
    api.resources :exam_scores
    api.resources :grading_levels
    api.resources :employee_grades
    api.resources :employee_positions
    api.resources :employee_categories
    api.resources :biometric_informations
  end
  #  map.connect ":class/:id/:attachment/image", :action => "paperclip_attachment", :controller => "user"
  map.connect 'reports/:action', :controller=>:report
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id/:id2'
  map.connect ':controller/:action/:id.:format'

end