class Api::NewsController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    count = 0
    if params[:count].to_i > 50
      count = 50
    elsif params[:count].to_i > 0
      count = params[:count]
    elsif (params[:count].nil? or params[:count].to_i < 0 == true)
      count = 3
    end
    @news = News.all(:limit => count)
    respond_to do |format|
      format.xml  { render :news }
    end
  end
end
