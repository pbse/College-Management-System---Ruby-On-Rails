#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class FinanceFee < ActiveRecord::Base
  
  belongs_to :finance_fee_collection ,:foreign_key => 'fee_collection_id'
  has_many   :finance_transactions ,:as=>:finance
  has_many   :cancelled_finance_transactions ,:as=>:finance
  has_many   :components, :class_name => 'FinanceFeeComponent', :foreign_key => 'fee_id'
  belongs_to :student
  belongs_to :batch
  has_many   :finance_transactions,:through=>:fee_transactions
  has_many   :fee_transactions
  has_one    :fee_refund
  named_scope :active , :joins=>[:finance_fee_collection] ,:conditions=>{:finance_fee_collections=>{:is_deleted=>false}}

  def check_transaction_done
    unless self.transaction_id.nil?
      return true
    else
      return false
    end
  end

  def former_student
    ArchivedStudent.find_by_former_id(self.student_id)
  end
  def due_date
    finance_fee_collection.due_date.strftime "%a,%d %b %Y"
  end

  def payee_name
    if student
      "#{student.full_name} - #{student.admission_no}"
    elsif former_student
      "#{former_student.full_name} - #{former_student.admission_no}"
    else
      "#{t('user_deleted')}"
    end
  end

  def self.new_student_fee(date,student)
    fee_particulars = date.finance_fee_particulars.all(:conditions=>"is_deleted=#{false} and batch_id=#{student.batch_id}").select{|par| (par.receiver==student or par.receiver==student.student_category or par.receiver==student.batch) }
    discounts=date.fee_discounts.all(:conditions=>"is_deleted=#{false} and batch_id=#{student.batch_id}").select{|par| (par.receiver==student or par.receiver==student.student_category or par.receiver==student.batch) }

    total_discount = 0
    total_payable=fee_particulars.map{|l| l.amount}.sum.to_f
    total_discount =discounts.map{|d| total_payable * d.discount.to_f/(d.is_amount? ? total_payable : 100)}.sum.to_f unless discounts.nil?
    balance=FedenaPrecision.set_and_modify_precision(total_payable-total_discount)
    FinanceFee.create(:student_id => student.id,:fee_collection_id => date.id,:balance=>balance,:batch_id=>student.batch_id)
  end
end
