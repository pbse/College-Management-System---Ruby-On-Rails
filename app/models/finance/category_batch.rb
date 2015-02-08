class CategoryBatch < ActiveRecord::Base
  belongs_to :batch
  belongs_to :finance_fee_category
  has_many :finance_fee_particulars , :foreign_key=>:finance_fee_category_id,:primary_key=>:finance_fee_category_id

  before_destroy :delete_particulars

  private

  def delete_particulars
    
    unless FeeCollectionBatch.find(:all,:joins=>"INNER JOIN finance_fee_collections on finance_fee_collections.id=fee_collection_batches.finance_fee_collection_id",:conditions=>"finance_fee_collections.fee_category_id=#{finance_fee_category_id} and fee_collection_batches.batch_id=#{batch_id}").present?
      FinanceFeeParticular.update_all("is_deleted= true","batch_id='#{batch_id}' and finance_fee_category_id='#{finance_fee_category_id}'")
    else
      return false
    end
  end
end

