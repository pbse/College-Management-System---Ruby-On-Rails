class FineRule < ActiveRecord::Base
  validates_uniqueness_of :fine_days, :scope=>[:fine_id]
  validates_inclusion_of :fine_amount, :in => 0..100,:unless=>:is_amount,:message=>:amount_in_percentage_cant_exceed_100
  belongs_to :fine
  belongs_to :user

  before_save :verify_precision


  named_scope :order_in_fine_days,:order=>'fine_days ASC'

  validates_presence_of :fine_amount,:fine_days
  validates_numericality_of :fine_amount,:fine_days,:allow_blank=>true

  def validate
    if (fine_days and fine_days <= 0)
      errors.add("fine_days",:cant_be_less_than_zero)
    end
    if (fine_amount and fine_amount <= 0)
      errors.add("fine_amount",:cant_be_less_than_zero)
    end
  end

  private

  def verify_precision
    if fine.fine_rules.collect(&:fine_days).include? fine_days 
      return false
    end
    self.fine_amount=FedenaPrecision.set_and_modify_precision self.fine_amount
  end
end
