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

class FinanceFeeCategory < ActiveRecord::Base
  belongs_to :batch
  belongs_to :student
  #
  has_many   :fee_particulars, :class_name => "FinanceFeeParticular"
  has_many   :fee_collections, :foreign_key =>"fee_category_id",:class_name => "FinanceFeeCollection"
  has_many   :fee_discounts
  has_many   :batches,:through=>:category_batches
  has_many   :category_batches

  before_create :check_name_uniqueness


  accepts_nested_attributes_for :category_batches,:allow_destroy => true
  cattr_reader :per_page

  @@per_page = 10

  validates_presence_of :name
  #validates_presence_of :batch_id,:message=>:not_specified
  #validates_uniqueness_of :name, :scope=>[:is_deleted],:if=> 'is_deleted == false'
  validates_format_of :name,:with=>/^\S.*\S$/i,:message => :should_not_contain_white_spaces_at_the_beginning_and_end


  def fees(student)
    FinanceFeeParticular.find_all_by_finance_fee_category_id(self.id,
      :conditions => ["((student_category_id IS NULL AND admission_no IS NULL )OR(student_category_id = '#{student.student_category_id}'AND admission_no IS NULL) OR (student_category_id IS NULL AND admission_no = '#{student.admission_no}')) and is_deleted=0"])
  end

  def check_fee_collection(batch_id)
    categories=FinanceFeeCategory.find(:all,:include=>:category_batches,:conditions=>"name='#{name}' and description='#{description}' and is_deleted=#{false}").uniq.map{|d| d if d.batch_id==batch_id}.compact
    if categories.present?
      category_id = FinanceFeeCategory.find_by_name_and_batch_id_and_is_deleted(name,batch_id,false).id
    else
      category_id=id
    end
    fee_collection =FeeCollectionBatch.find(:all,:joins=>"INNER JOIN finance_fee_collections on finance_fee_collections.id=fee_collection_batches.finance_fee_collection_id",:conditions=>"finance_fee_collections.fee_category_id=#{category_id} and fee_collection_batches.batch_id=#{batch_id}")
    #fee_collection = FinanceFeeCollection.find_all_by_fee_category_id(self.id,:conditions=>{:is_deleted=>0})
    fee_collection.empty? ? true : false
  end

  def check_fee_collection_for_additional_fees
    flag =0
    fee_collection = FinanceFeeCollection.find_all_by_fee_category_id(self.id)
    fee_collection.each do |fee|
      flag = 1 if fee.check_fee_category == true
    end
    flag == 1 ?  true : false

  end

  def delete_particulars
    self.fee_particulars.each do |fees|
      fees.update_attributes(:is_deleted => true)
    end
  end

  def student_fee_balance(student,date)
    particulars= FinanceFeeParticular.find_all_by_finance_fee_category_id(self.id,
      :conditions => ["((student_category_id IS NULL AND admission_no IS NULL )OR(student_category_id = '#{student.student_category_id}'AND admission_no IS NULL) OR (student_category_id IS NULL AND admission_no = '#{student.admission_no}')) and is_deleted=0"])
    financefee = student.finance_fee_by_date(date)

    paid_fees = FinanceTransaction.find(:all,:conditions=>"FIND_IN_SET(id,\"#{financefee.transaction_id}\")") unless financefee.transaction_id.blank?

    batch_discounts = BatchFeeDiscount.find_all_by_finance_fee_category_id(self.id)
    student_discounts = StudentFeeDiscount.find_all_by_finance_fee_category_id_and_receiver_id(self.id,student.id)
    category_discounts = StudentCategoryFeeDiscount.find_all_by_finance_fee_category_id(self.id, :joins=>'INNER JOIN students ON fee_discounts.receiver_id = students.student_category_id')
    total_discount = 0
    total_discount += batch_discounts.map{|s| s.discount}.sum unless batch_discounts.nil?
    total_discount += student_discounts.map{|s| s.discount}.sum unless student_discounts.nil?
    total_discount += category_discounts.map{|s| s.discount}.sum unless category_discounts.nil?
    if total_discount > 100
      total_discount = 100
    end

    total_fees =0
    unless particulars.nil?
      total_fees += particulars.collect{|x|x.amount.to_f}.sum
      total_fees = (total_fees - ((total_fees*total_discount)/100))

      unless paid_fees.nil?
        paid = 0
        paid += paid_fees.collect{|x|x.amount.to_f}.sum
        total_fees -= paid
        trans = FinanceTransaction.find(financefee.transaction_id)
        unless trans.nil?
          total_fees += trans.fine_amount.to_f if trans.fine_included
        end
      end
    end
    return total_fees
  end

  def self.common_active
    #    finace_fee_category=self.find(:all,:conditions=>{:is_master=>1,:is_deleted=>0,:batches=>{:is_active=>1,:is_deleted=>0}},:joins=>[:batch])
    self.find(:all , :conditions => ["finance_fee_categories.is_master = '#{1}' and finance_fee_categories.is_deleted = '#{false}'"], :joins=>"INNER JOIN batches on finance_fee_categories.batch_id = batches.id AND batches.is_active = 1 AND batches.is_deleted = 0 ").reject{|s| s.fee_particulars.active.empty?}
  end


#  def is_collection_open
#    collection = FinanceFeeCollection.find_all_by_fee_category_id(self.id,:conditions=>"start_date < '#{Date.today.to_date}' and due_date > '#{Date.today.to_date}'")
#    collection.reject!{ |c|c.no_transaction_present } unless collection.nil?
#    collection.present?
#  end

  def have_common_particular?
    self.fee_particulars.find(:all,:conditions=>{:student_category_id=>nil,:admission_no=>nil,:is_deleted=>false}).count > 0 ? true : false
  end

  def create_associates(cat_id,batch_id)

    particulars=FinanceFeeParticular.find(:all,:conditions=>"finance_fee_category_id=#{cat_id} and batch_id=#{batch_id} and is_deleted=#{false}")
    discounts=FeeDiscount.find(:all,:conditions=>"finance_fee_category_id=#{cat_id} and batch_id=#{batch_id} and is_deleted=#{false}")
    particulars.each do |particular|

      attributes=particular.attributes.delete_if{|key,values| ["id","finance_fee_category_id"].include? key}
      attributes["finance_fee_category_id"]=self.id
      FinanceFeeParticular.create(attributes)
    end
    discounts.each do |discount|

      attributes=discount.attributes.delete_if{|key,values| ["id","finance_fee_category_id"].include? key}
      attributes["finance_fee_category_id"]=self.id

      FeeDiscount.create(attributes)
    end
    CategoryBatch.create(:finance_fee_category_id=>id,:batch_id=>batch_id)
  end

  def check_category_name_exists(batch)
   ds=id.to_i
   if batch.finance_fee_categories.all(:conditions=>"name = '#{name}' and finance_fee_categories.id <> #{ds}").present?

    return false

   else
     return true
   end
  end

  def check_name_uniqueness
    a=true
    category_batches.each{|cb| a=a & check_category_name_exists(cb.batch)}
    errors.add_to_base(t('name_already_taken')) unless a
    return a
  end


end
