class Api::ExamScoresController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @exam_scores = ExamScore.search(params[:search])

    respond_to do |format|
      unless params[:search].present? and params[:search][:exam_exam_group_name_equals].present? and params[:search][:exam_exam_group_batch_name_equals].present? and params[:search][:exam_exam_group_batch_course_code_equals].present?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :exam_scores }
      end
    end
  end

  def create
    @xml = Builder::XmlMarkup.new
    batch = Batch.active.find(:first,:conditions => ["CONCAT(courses.code, ' - ',name) LIKE ?",params[:batch]],:joins=>:course)
    exam_group = batch.nil? ? nil : batch.exam_groups.find_by_name(params[:exam_group_name])
    exam = exam_group.nil? ? nil : exam_group.try(:exams).find_by_subject_id(Subject.active.find_by_code_and_batch_id(params[:subject_code],batch.try(:id)).try(:id))
    student = Student.find_by_admission_no(params[:admission_no]).try(:id)
    grading_level = GradingLevel.for_batch(batch.try(:id)).find_by_name(params[:grade]).try(:id)
    grading_level ||= GradingLevel.default.find_by_name(params[:grade]).try(:id)
    @exam_score = ExamScore.new(:exam_id => exam.try(:id),:student_id => student,:marks => params[:marks],:remarks => params[:remarks],:grading_level_id => grading_level,:is_failed => params[:is_failed] == "true" ? true : false) 
    respond_to do |format|
      if (params[:exam_group_name].present? and params[:subject_code].present? and params[:admission_no].present? and params[:batch].present? and params[:marks].present?)
        unless @exam_score.nil?
          if @exam_score.save
            format.xml  { render :exam_score, :status => :created }
          else
            format.xml  { render :xml => @exam_score.errors, :status => :unprocessable_entity }
          end
        else
          render "single_access_tokens/500.xml", :status => :bad_request  and return
        end
      else
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      end
    end
  end

  def update
    @xml = Builder::XmlMarkup.new
    batch = Batch.active.find(:first,:conditions => ["CONCAT(courses.code, ' - ',name) LIKE ?",params[:batch]],:joins=>:course)
    exam_group = batch.exam_groups.find_by_name(params[:exam_group_name])
    exam = exam_group.try(:exams).find_by_subject_id(Subject.active.find_by_code_and_batch_id(params[:subject_code],batch.try(:id)).try(:id)) unless exam_group.nil?
    student = Student.find_by_admission_no(params[:id]).try(:id)
    grading_level = GradingLevel.for_batch(batch.try(:id)).find_by_name(params[:grade]).try(:id)
    grading_level ||= GradingLevel.default.find_by_name(params[:grade]).try(:id)
    @exam_score = exam.exam_scores.find_by_student_id(student) unless exam.nil?
    respond_to do |format|
      unless (params[:exam_group_name].present? and params[:subject_code].present? and params[:admission_no].present? and params[:batch].present? and params[:marks].present?)
        unless @exam_score.nil?
          if @exam_score.update_attributes(:marks => params[:marks],:remarks => params[:remarks],:grading_level_id => grading_level,:is_failed => params[:is_failed] == "true" ? true : false)
            format.xml  { render :exam_score, :status => :created }
          else
            format.xml  { render :xml => @exam_score.errors, :status => :unprocessable_entity }
          end
        else
          render "single_access_tokens/500.xml", :status => :bad_request  and return
        end
      else
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      end
    end
  end
end
