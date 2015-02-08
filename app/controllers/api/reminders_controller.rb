class Api::RemindersController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @reminders = Reminder.search(params[:search]).scoped(:conditions => ["DATE(reminders.created_at)='#{params[:created_at]}'"])
    respond_to do |format|
      unless (params[:search].present? and params[:search][:to_user_username_equals].present? and params[:created_at].present?)
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :reminders }
      end
    end
  end

  def create
    @xml = Builder::XmlMarkup.new
    @reminder = Reminder.new
    @reminder.user = User.find_by_username(params[:sender])
    @reminder.to_user = User.find_by_username(params[:receiver])
    @reminder.subject = params[:subject]
    @reminder.body = params[:body]
    respond_to do |format|
      if @reminder.save
        format.xml  { render :reminder, :status => :created }
      else
        format.xml  { render :xml => @reminder.errors, :status => :unprocessable_entity }
      end
    end
  end
end
