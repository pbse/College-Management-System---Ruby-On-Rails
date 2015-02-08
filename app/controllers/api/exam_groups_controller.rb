class Api::ExamGroupsController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @exam_groups = ExamGroup.search(params[:search])

    respond_to do |format|
      unless params[:search].present? 
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :exam_groups }
      end
    end
  end

  def create
    @xml = Builder::XmlMarkup.new
    @exam_group = ExamGroup.new
    @exam_group.name = params[:name]
    @exam_group.batch = Batch.all.select{|batch| batch.full_name == params[:batch_name]}.first.try(:id)
    @exam_group.exam_type = params[:exam_type]
    
    respond_to do |format|
      if @exam_group.save
        format.xml  { render :exam_group, :status => :created }
      else
        format.xml  { render :xml => @exam_group.errors, :status => :unprocessable_entity }
      end
    end
  end
end
