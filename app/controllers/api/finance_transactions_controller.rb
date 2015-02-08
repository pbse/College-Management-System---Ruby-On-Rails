class Api::FinanceTransactionsController < ApiController
  filter_access_to :all
  
  def index
    @xml = Builder::XmlMarkup.new
    @finance_transactions = FinanceTransaction.search(params[:search])

    respond_to do |format|
      unless params[:search].present?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :finance_transactions }
      end
    end
  end

end
