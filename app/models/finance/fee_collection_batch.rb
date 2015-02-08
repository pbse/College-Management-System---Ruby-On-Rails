class FeeCollectionBatch < ActiveRecord::Base
  belongs_to :batch
  belongs_to :finance_fee_collection
  before_destroy :delete_finance_fees
  after_create :create_associates




  private

  
  def create_associates
    discounts=FeeDiscount.find_all_by_finance_fee_category_id_and_batch_id(finance_fee_collection.fee_category_id,batch_id,:conditions=>"is_deleted=0")
    discounts.each do |discount|
      CollectionDiscount.create(:fee_discount_id=>discount.id,:finance_fee_collection_id=>finance_fee_collection_id)
    end
    
    particlulars = FinanceFeeParticular.find_all_by_finance_fee_category_id_and_batch_id(finance_fee_collection.fee_category_id,batch_id,:conditions=>"is_deleted=0")
    particlulars.each do |particular|
      CollectionParticular.create(:finance_fee_particular_id=>particular.id,:finance_fee_collection_id=>finance_fee_collection_id)
    end
  end
  
  
  def delete_finance_fees
    FinanceFee.find(:all,:joins=>"INNER JOIN students on students.id=finance_fees.student_id",:conditions=>"students.batch_id=#{batch_id} and finance_fees.fee_collection_id=#{finance_fee_collection_id}").each{|fee| fee.destroy}
  end
end
