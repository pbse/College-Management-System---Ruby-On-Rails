class RefundRule < ActiveRecord::Base
  belongs_to :finance_fee_collection
  belongs_to :user
  validates_uniqueness_of :refund_validity,:scope=>[:finance_fee_collection_id]
  validates_presence_of :finance_fee_collection_id,:name,:refund_percentage
  validates_numericality_of :refund_percentage,:allow_blank=>true
  validates_inclusion_of :refund_percentage, :in => 1..100,:message=>:should_be_in_the_range_of_1_to_100,:allow_blank=>true
  
#  def validate
#
#    if refund_percentage.to_f <= 0.00 or refund_percentage.to_f > 100.00
#      errors.add("refund_percentage","must be between 0 to 100")
#    end
#
#  end

end
