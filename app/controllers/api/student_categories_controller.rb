class Api::StudentCategoriesController < ApiController
  filter_access_to :all
  def index
    @xml = Builder::XmlMarkup.new
    @student_categories = StudentCategory.active

    respond_to do |format|
      format.xml{ render :student_categories}
    end
  end
end
