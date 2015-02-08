class Api::UsersController < ApiController

  def show
    @xml = Builder::XmlMarkup.new
    @user = User.active.find_by_username(params[:id])
    @privileges = @user.privileges.all.map(&:description)
    
    respond_to do |format|
      unless @user.nil?
        format.xml  { render :user }
      else
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      end
    end
    
  end
  
end
