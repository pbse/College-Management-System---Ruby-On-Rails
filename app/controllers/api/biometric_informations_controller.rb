class Api::BiometricInformationsController < ApiController
  filter_access_to :all
  
  def show
    @xml = Builder::XmlMarkup.new
    @biometric_information = BiometricInformation.find_by_biometric_id(params[:id])

    respond_to do |format|
      if (params[:id].nil? or @biometric_information.nil?)
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml {render :biometric_info}
      end
    end
  end

end
