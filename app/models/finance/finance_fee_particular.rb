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

class FinanceFeeParticular < ActiveRecord::Base

  belongs_to :finance_fee_category
  belongs_to :student_category
  belongs_to :receiver,:polymorphic=>true
  belongs_to :batch
  has_many   :finance_fee_collections,:through=>:collection_particulars
  has_many   :collection_particulars
  has_many   :fee_discounts
  validates_presence_of :name,:amount,:finance_fee_category_id,:batch_id,:receiver_id,:receiver_type
  validates_numericality_of :amount, :greater_than_or_equal_to => 0, :message => :must_be_positive, :allow_blank => true
  named_scope :active,{ :conditions => { :is_deleted => false}}
  named_scope :batch_particulars,{:conditions=>{:is_deleted=>false,:receiver_type=>'Batch'},:group=>["name,receiver_type"]}
  named_scope :category_particulars,{:conditions=>["is_deleted=false and (receiver_type='Batch' or receiver_type='StudentCategory')"],:group=>["name,receiver_type"]}
  cattr_reader :per_page
  @@per_page = 10
  before_save :verify_precision
  before_update :check_discounts

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
  end
  
  def deleted_category
    flag = false
    category = receiver if receiver_type=='StudentCategory'
    if category
      flag = true if category.is_deleted
    end
    return flag
  end

  def student_name
    if receiver_id.present?
      student = Student.find_by_id(receiver_id)
      student ||= ArchivedStudent.find_by_former_id(receiver_id)
      student.present? ? "#{student.first_name} &#x200E;(#{student.admission_no})&#x200E;" : "N.A. (N.A.)"
    end
  end

  def collection_exist
    collection_ids=finance_fee_category.fee_collections.collect(&:id)
    if CollectionParticular.find_by_finance_fee_particular_id_and_finance_fee_collection_id(id,collection_ids)
    errors.add_to_base(t('collection_exists_for_this_category_cant_edit_this_particular'))
      return false
    else
      return true
    end
  end

  def delete_particular
      update_attributes(:is_deleted=>true)
  end

  def self.student_category_batches(name,type)
    Batch.find(:all,:joins=>"INNER JOIN finance_fee_particulars on batches.id=finance_fee_particulars.batch_id INNER JOIN students on students.batch_id=batches.id",:conditions=>"finance_fee_particulars.name='#{name}' and (finance_fee_particulars.receiver_type='#{type}' and finance_fee_particulars.is_deleted<>true)").uniq
    #find(:all,:joins=>"INNER JOIN batches on batches.id=finance_fee_particulars.batch_id INNER JOIN students on students.batch_id=batches.id",:conditions=>"finance_fee_particulars.name='#{name}' and (finance_fee_particulars.receiver_type='#{type}' and finance_fee_particulars.is_deleted<>true)").map{|b| b.batch}.uniq
  end

  private

  def check_discounts
    if FeeDiscount.find(:all,:conditions=>"is_deleted = '#{false}' and finance_fee_category_id=#{finance_fee_category_id} and batch_id=#{batch_id}").present?
      errors.add_to_base(t('discounts_exists_for_this_category_cant_delete_or_edit_this_particular'))
      return false
    end
  end


end
