class CollectionParticular < ActiveRecord::Base
  belongs_to :finance_fee_particular
  belongs_to :finance_fee_collection
end
