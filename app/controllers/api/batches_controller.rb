class Api::BatchesController < ApiController
  filter_access_to :all
  def index
    @xml = Builder::XmlMarkup.new
    @batches = Batch.active.search(params[:search])
    
    respond_to do |format|
      unless params[:search].present?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :batches }
      end
    end
  end

  def create
    @xml = Builder::XmlMarkup.new
    @course = Course.active.find_by_code(params[:course_code])
    @batch = @course.batches.build
    @batch.name = params[:batch_name]
    @batch.start_date = params[:batch_start_date]
    @batch.end_date = params[:batch_end_date]
    respond_to do |format|
      if @batch.save
        format.xml  { render :batch, :status => :created }
      else
        format.xml  { render :xml => @batch.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @xml = Builder::XmlMarkup.new
    @course = Course.active.find_by_code(params[:course_code])
    @batch = @course.batches.active.find_by_name(params[:id])
    @batch.name = params[:batch_name]
    @batch.start_date = params[:batch_start_date]
    @batch.end_date = params[:batch_end_date]

    respond_to do |format|
      if @batch.save
        format.xml  { render :batch }
      else
        format.xml  { render :xml => @batch.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @xml = Builder::XmlMarkup.new
    @course = Course.active.find_by_code(params[:course_code])
    @batch = @course.batches.active.find_by_name(params[:id])
    respond_to do |format|
      if @batch.students.empty? and @batch.subjects.empty?
        @batch.inactivate
        format.xml  { render :delete }
      else
        @batch.errors.add_to_base("Please delete all the batch students first") unless @batch.students.empty?
        @batch.errors.add_to_base("Please delete all the batch subjects first") unless @batch.students.empty?
        format.xml  { render :xml => @batch.errors }
      end
    end
  end

end
