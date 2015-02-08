module ApiHelper
  def current_school_detail
    SchoolDetail.first||SchoolDetail.new
  end
end
