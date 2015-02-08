class Api::SchoolsController < ApiController
  filter_access_to :all
  
  def index
    @xml = Builder::XmlMarkup.new
    @configurations = Configuration.get_school_details

    respond_to do |format|
      format.xml  { render :school_detail }
    end
  end

end
