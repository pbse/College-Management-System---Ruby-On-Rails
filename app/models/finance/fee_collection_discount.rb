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



class FeeCollectionDiscount < ActiveRecord::Base

  belongs_to :finance_fee_collection
  before_save :verify_precision

  def verify_precision
    self.discount = FedenaPrecision.set_and_modify_precision self.discount
  end
  
  def category_name
    c =StudentCategory.find(self.receiver_id)
    c.name unless c.nil?
  end

  def student_name
    s = Student.find_by_id(self.receiver_id)
    s ||= ArchivedStudent.find_by_former_id(self.receiver_id)
    s.present? ? "#{s.first_name} (#{s.admission_no})" : "N.A. (N.A.)"
  end

  def total_payable(student = nil)
    if student.nil?
      payable = finance_fee_collection.fee_category.fee_particulars.active.map(&:amount).compact.flatten.sum
    else
      payable = finance_fee_collection.fees_particulars(student).select{|f| (f.is_deleted==false)}.map(&:amount).compact.flatten.sum
    end
    payable
  end

  def discount(student = nil)
    if is_amount == false
      super
    elsif is_amount == true
      payable = student.nil? ? total_payable : total_payable(student)
      percentage = (super.to_f / payable.to_f).to_f * 100.to_f
      percentage
    end
  end
end
