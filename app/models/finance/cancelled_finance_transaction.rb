class CancelledFinanceTransaction < ActiveRecord::Base
  belongs_to :category, :class_name => 'FinanceTransactionCategory', :foreign_key => 'category_id'
  belongs_to :student ,:primary_key => 'payee_id'
  belongs_to :employee ,:primary_key => 'payee_id'
  belongs_to :instant_fee,:foreign_key=>'finance_id',:conditions=>'payee_id is NULL'
  belongs_to :finance, :polymorphic => true
  belongs_to :payee, :polymorphic => true
  belongs_to :master_transaction,:class_name => "FinanceTransaction"
  belongs_to :user

  after_create :update_collection_name

  def update_collection_name
    update_attributes(:transaction_date=>created_at.strftime("%m-%d-%Y"))
  end
end
