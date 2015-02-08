class FeeTransaction < ActiveRecord::Base
  belongs_to :finance_transaction
  belongs_to :finance_fee
end
