class CollectionDiscount < ActiveRecord::Base
  belongs_to :fee_discount
  belongs_to :finance_fee_collection
end
