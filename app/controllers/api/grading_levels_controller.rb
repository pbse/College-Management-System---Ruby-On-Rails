class Api::GradingLevelsController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    batch = Batch.active.find(:first,:conditions => ["CONCAT(courses.code, ' - ',name) LIKE ?",params[:batch]],:joins=>:course).try(:id)
    @grading_levels = GradingLevel.for_batch(batch)
    @grading_levels = @grading_levels.blank? ? GradingLevel.default : @grading_levels

    respond_to do |format|
      unless params[:batch].present?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :grading_levels }
      end
    end
  end
end
