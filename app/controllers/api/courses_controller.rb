class Api::CoursesController < ApiController
  filter_access_to :all
  
  def index
    @xml = Builder::XmlMarkup.new
    @courses = Course.active.search(params[:search])
    
    respond_to do |format|
      format.xml  { render :courses }
    end
  end

  def create
    @xml = Builder::XmlMarkup.new
    @course = Course.new
    @course.course_name = params[:course_name]
    @course.code = params[:course_code]
    @course.section_name = params[:section_name]
    @course.grading_type = Course::GRADINGTYPES.index(params[:grading_type])
    @course.grading_type ||= 0
    @batch = @course.batches.build
    @batch.name = params[:initial_batch_name]
    @batch.start_date = params[:batch_start_date]
    @batch.end_date = params[:batch_end_date]
    respond_to do |format|
      if @course.save
        format.xml  { render :course, :status => :created }
      else
        format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @xml = Builder::XmlMarkup.new
    @course = Course.active.find_by_code(params[:id])
    @course.course_name = params[:course_name]
    @course.code = params[:course_code]
    @course.section_name = params[:section_name]
    @course.grading_type = Course::GRADINGTYPES.index(params[:grading_type])
    respond_to do |format|
      if @course.save
        format.xml  { render :course }
      else
        format.xml  { render :xml => @course.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @xml = Builder::XmlMarkup.new
    @course = Course.active.find_by_code(params[:id])
    
    respond_to do |format|
      if @course.batches.active.empty?
        @course.inactivate
        format.xml  { render :delete }
      else
        @course.errors.add_to_base("Please delete all the batches before deleting the course")
        format.xml  { render :xml => @course.errors }
      end
    end
  end
end
