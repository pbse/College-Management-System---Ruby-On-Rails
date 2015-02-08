class FeeRefund < ActiveRecord::Base
  belongs_to :finance_fee
  belongs_to :finance_transaction
  belongs_to :user
  belongs_to :refund_rule
  validates_uniqueness_of :finance_fee_id,:scope=>[:refund_rule_id]

  def refunded_by
    user.present?? user.first_name : "#{t('user_deleted')}"
  end
end
