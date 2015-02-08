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

class FinanceFeeCollection < ActiveRecord::Base
  belongs_to :batch
  has_many :finance_fees, :foreign_key =>"fee_collection_id",:dependent=>:destroy
  has_many :finance_transactions, :through => :finance_fees
  has_many :students, :through => :finance_fees
  has_many :fee_collection_particulars ,:dependent=>:destroy
  has_many :fee_collection_discounts   ,:dependent=>:destroy
  belongs_to :fee_category,:class_name => "FinanceFeeCategory"
  has_one :event, :as => :origin
  belongs_to :fine,:conditions=>"is_deleted is false"
  has_many   :batches,:through=>:fee_collection_batches
  has_many   :fee_collection_batches
  has_many   :fee_discounts,:through=>:collection_discounts
  has_many   :collection_discounts
  has_many   :finance_fee_particulars,:through=>:collection_particulars
  has_many   :collection_particulars
  has_many   :refund_rules




  validates_presence_of :name,:start_date,:fee_category_id,:end_date,:due_date

  after_create :create_associates

  def validate
    unless self.start_date.nil? or self.end_date.nil?
      errors.add_to_base :start_date_cant_be_after_end_date if self.start_date > self.end_date
      errors.add_to_base :start_date_cant_be_after_due_date if self.start_date > self.due_date
      errors.add_to_base :end_date_cant_be_after_due_date if self.end_date > self.due_date
    else
    end
  end

  def full_name
    "#{name} - #{start_date.to_s}"
  end

  def fee_transactions(student_id)
    FinanceFee.find_by_fee_collection_id_and_student_id(self.id,student_id)
  end

  def check_transaction(transactions)
    transactions.finance_fees_id.nil? ? false : true

  end

  def fee_table
    self.finance_fees.all(:conditions=>"is_paid = 0")
  end

  def self.shorten_string(string, count)
    if string.length >= count
      shortened = string[0, count]
      splitted = shortened.split(/\s/)
      words = shortened.length
      splitted[0, words-1].join(" ") + ' ...'
    else
      string
    end
  end

  def check_fee_category(batch)
   if FinanceTransaction.find(:all,:joins=>"INNER JOIN fee_transactions on finance_transactions.id = fee_transactions.finance_transaction_id
INNER JOIN finance_fees on finance_fees.id=fee_transactions.finance_fee_id
INNER JOIN students on students.id=finance_fees.student_id",:conditions=>["finance_fees.fee_collection_id=#{id} and students.batch_id=#{batch}"]).present?
      return false
   else
     return true
   end
  end
#    finance_fees = FinanceFee.find_all_by_fee_collection_id(self.id)
#    flag = 1
#    finance_fees.each do |f|
#      flag = 0 unless f.transaction_id.nil?
#    end
#    flag == 1 ? true : false
#  end

#  def no_transaction_present
#    f = FinanceFee.find_all_by_fee_collection_id(self.id)
#    f.reject! {|x|x.transaction_id.nil?} unless f.nil?
#    f.blank?
#  end

  def create_associates

#    discounts=FeeDiscount.find_all_by_finance_fee_category_id(self.fee_category_id,:conditions=>"is_deleted=0")
#    discounts.each do |discount|
#      CollectionDiscount.create(:fee_discount_id=>discount.id,:finance_fee_collection_id=>id)
#    end
#    particlulars = FinanceFeeParticular.find_all_by_finance_fee_category_id(self.fee_category_id,:conditions=>"is_deleted=0")
#    particlulars.each do |particular|
#      CollectionParticular.create(:finance_fee_particular_id=>particular.id,:finance_fee_collection_id=>id)
#    end
    #
    #    batch_discounts = BatchFeeDiscount.find_all_by_finance_fee_category_id(self.fee_category_id)
    #    batch_discounts.each do |discount|
    #      discount_attributes = discount.attributes
    #      discount_attributes.delete "type"
    #      discount_attributes.delete "finance_fee_category_id"
    #      discount_attributes["finance_fee_collection_id"]= self.id
    #      BatchFeeCollectionDiscount.create(discount_attributes)
    #    end
    #    category_discount = StudentCategoryFeeDiscount.find_all_by_finance_fee_category_id(self.fee_category_id)
    #    category_discount.each do |discount|
    #      discount_attributes = discount.attributes
    #      discount_attributes.delete "type"
    #      discount_attributes.delete "finance_fee_category_id"
    #      discount_attributes["finance_fee_collection_id"]= self.id
    #      StudentCategoryFeeCollectionDiscount.create(discount_attributes)
    #    end
    #    student_discount = StudentFeeDiscount.find_all_by_finance_fee_category_id(self.fee_category_id)
    #    student_discount.each do |discount|
    #      discount_attributes = discount.attributes
    #      discount_attributes.delete "type"
    #      discount_attributes.delete "finance_fee_category_id"
    #      discount_attributes["finance_fee_collection_id"]= self.id
    #      StudentFeeCollectionDiscount.create(discount_attributes)
    #    end
    #    particlulars = FinanceFeeParticular.find_all_by_finance_fee_category_id(self.fee_category_id,:conditions=>"is_deleted=0")
    #    particlulars.each do |p|
    #      particlulars_attributes = p.attributes
    #      particlulars_attributes.delete "finance_fee_category_id"
    #      particlulars_attributes["finance_fee_collection_id"]= self.id
    #      FeeCollectionParticular.create(particlulars_attributes)
    #    end
  end

  def fees_particulars(student)
    FeeCollectionParticular.find_all_by_finance_fee_collection_id(self.id,
      :conditions => ["((student_category_id IS NULL AND admission_no IS NULL )OR(student_category_id = '#{student.student_category_id}'AND admission_no IS NULL) OR (student_category_id IS NULL AND admission_no = '#{student.admission_no}')) and is_deleted=0"])
  end

  def transaction_total(start_date,end_date,batch_id)
    total=0
    FinanceFee.find(:all,:joins=>"INNER JOIN students on finance_fees.student_id=students.id ",:conditions=>["students.batch_id='#{batch_id}' and finance_fees.fee_collection_id='#{id}'"]).each do |ff|
      total =total+ff.finance_transactions.all(:conditions=>"transaction_date >= '#{start_date}' AND transaction_date <= '#{end_date}'").map{|t|t.amount}.sum
    end
    #trans=finance_fees.map{|ff| ff.finance_transactions.all(:conditions=>"transaction_date >= '#{start_date}' AND transaction_date <= '#{end_date}'")}
    #trans = self.finance_transactions.all(:conditions=>"transaction_date >= '#{start_date}' AND transaction_date <= '#{end_date}'")
    #total = trans.map{|t|t.amount}.sum
    return total
  end

  def student_fee_balance(student)
#    particulars= self.fees_particulars(student)
    financefee = self.fee_transactions(student.id)
    particulars=finance_fee_particulars.all(:conditions=>"batch_id=#{student.batch_id}").select{|par| (par.receiver.present?) and (par.receiver==student or par.receiver==student.student_category or par.receiver==student.batch)}
    paid_fees = financefee.finance_transactions if financefee.present?

     discounts=fee_discounts.all(:conditions=>"batch_id=#{student.batch_id}").select{|par| (par.receiver.present?) and (par.receiver==student or par.receiver==student.student_category or par.receiver==student.batch)}
    total_discount = 0
    total_fees=particulars.map{|s| s.amount}.sum.to_f
    total_discount =discounts.map{|d| total_fees * d.discount.to_f/(d.is_amount? ? total_fees : 100)}.sum.to_f unless discounts.nil?

    total_fees -= total_discount

    unless paid_fees.nil?
      paid = 0
      fine = 0
      paid += paid_fees.collect{|x|x.amount.to_f}.sum
      total_fees -= paid
      #trans = FinanceTransaction.find(financefee.transaction_id)
      fine += paid_fees.collect{|f|f.fine_amount.to_f}.sum
      total_fees += fine
      #unless trans.nil?
      #total_fees += trans.fine_amount.to_f if trans.fine_included
      # end
    end
    return total_fees
  end
  def fee_collection_emails
    emails=[]
    emails<<self.students.collect(&:email)
    self.students.each do|s| emails<<s.guardians.collect(&:email);end
    emails.flatten.reject!{|e| e.blank?}
  end


  def self.fee_collection_details(parameters)
    sort_order=parameters[:sort_order]
    batch_id=parameters[:batch_id]
    if batch_id.nil?
      if sort_order.nil?
        fee_collection= FinanceFeeCollection.all(:select=>"finance_fee_collections.*,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name",:joins=>"INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:conditions=>{:batches=>{:is_deleted=>false,:is_active=>true},:is_deleted=>false},:order=>'name ASC')
      else
        fee_collection= FinanceFeeCollection.all(:select=>"finance_fee_collections.*,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name",:joins=>"INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:conditions=>{:batches=>{:is_deleted=>false,:is_active=>true},:is_deleted=>false},:order=>sort_order)
      end
    else
      if sort_order.nil?
        fee_collection= FinanceFeeCollection.all(:select=>"finance_fee_collections.*,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name",:joins=>"INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:conditions=>{:batches=>{:is_deleted=>false,:is_active=>true,:id=>batch_id[:batch_ids]},:is_deleted=>false},:order=>'name ASC')
      else
        fee_collection= FinanceFeeCollection.all(:select=>"finance_fee_collections.*,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name",:joins=>"INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:conditions=>{:batches=>{:is_deleted=>false,:is_active=>true,:id=>batch_id[:batch_ids] },:is_deleted=>false},:order=>sort_order)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('fee_collection')} #{t('name')}","#{t('batch_name')}","#{t('category_name')}","#{t('start_date')}","#{t('end_date')}","#{t('due_date')}"]
    data << col_heads
    fee_collection.each_with_index do |f,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{f.name}"
      col<< "#{f.batch_name}"
      col<< "#{f.category_name}"
      col<< "#{f.start_date}"
      col<< "#{f.end_date}"
      col<< "#{f.due_date}"
      col=col.flatten
      data<< col
    end
    return data
  end

  def self.batch_fee_collections(parameters)
    batch_id=parameters[:batch_id]
    fee_collections= FinanceFeeCollection.all(:select=>"finance_fee_collections.id,finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,sum(IF(students.id IS NOT NULL ,finance_fees.balance,NULL)) as balance,count(IF(finance_fees.balance!='0.0' and students.id IS NOT NULL,finance_fees.id,NULL)) as students_count",:joins=>"LEFT OUTER JOIN `finance_fees` ON finance_fees.fee_collection_id = finance_fee_collections.id LEFT OUTER JOIN `batches` ON `batches`.id = `finance_fees`.batch_id LEFT OUTER JOIN students on students.id = finance_fees.student_id ",:conditions=>{:finance_fees=>{:batch_id=>batch_id},:is_deleted=>false},:group=>"id",:order=>"balance DESC")
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      fee_collections_transport= TransportFeeCollection.all(:select=>"transport_fee_collections.id,name,start_date,end_date,due_date,sum(IF(transport_fees.transaction_id is NULL and receiver_type='Student' and students.id IS NOT NULL,transport_fees.bus_fare,NULL)) as balance, count(DISTINCT IF(transport_fees.transaction_id is NULL and receiver_type='Student' and students.id IS NOT NULL,transport_fees.id,NULL)) as students_count",:joins=>"INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:conditions=>{:batch_id=>batch_id,:is_deleted=>false,:transport_fees=>{:transaction_id=>nil}},:group=>"id")
      fee_collections+=fee_collections_transport
    end
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      fee_collections_hostel=HostelFeeCollection.all(:select=>"hostel_fee_collections.id,name,start_date,end_date,due_date,sum(IF(hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL ,hostel_fees.rent,NULL)) as balance, count(DISTINCT IF(hostel_fees.finance_transaction_id is NULL and students.id IS NOT NULL,hostel_fees.id,NULL)) as students_count",:joins=>"INNER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id LEFT OUTER JOIN students on students.id=hostel_fees.student_id",:conditions=>{:batch_id=>batch_id,:is_deleted=>false,:hostel_fees=>{:finance_transaction_id=>nil}},:group=>"id")
      fee_collections+=fee_collections_hostel
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('start_date')}","#{t('end_date')}","#{t('due_date')}","#{t('students')}","#{t('balance')}(#{Configuration.currency})"]
    data << col_heads
    fee_collections.each_with_index do |b,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{b.name}"
      col<< "#{b.start_date.to_date}"
      col<< "#{b.end_date.to_date}"
      col<< "#{b.due_date.to_date}"
      col<< "#{b.students_count}"
      col<< "#{b.balance.nil?? 0 : b.balance}"
      col=col.flatten
      data<< col
    end
    return data
  end


  def delete_collection(batch)
    FeeCollectionBatch.destroy_all(:finance_fee_collection_id=>id,:batch_id=>batch)
    batch_event=BatchEvent.find(:first,:joins=>"INNER JOIN events on events.id=batch_events.event_id",:conditions=>"batch_events.batch_id=#{batch} and events.origin_id=#{id} and events.origin_type='FinanceFeeCollection'")
     batch_event.destroy if batch_event
    #update_attributes(:is_deleted => true)
    unless fee_collection_batches.present?
      Event.destroy_all(:origin_type=>"FinanceFeeCollection",:origin_id=>id)
      update_attributes(:is_deleted => true)
      CollectionParticular.destroy_all(:finance_fee_collection_id=>id)
    end
  end

  def fine_to_pay(student)
    financefee = student.finance_fee_by_date(self)
     fee_particulars = finance_fee_particulars.all(:conditions=>"batch_id=#{financefee.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==student or par.receiver==student.student_category or par.receiver==financefee.batch) }
      discounts=fee_discounts.all(:conditions=>"batch_id=#{financefee.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==student or par.receiver==student.student_category or par.receiver==financefee.batch) }

      total_discount = 0
      total_payable=fee_particulars.map{|s| s.amount}.sum.to_f
      total_discount =discounts.map{|d| total_payable * d.discount.to_f/(d.is_amount? ? total_payable : 100)}.sum.to_f unless discounts.nil?
      bal=(total_payable-total_discount).to_f
      days=(Date.today-due_date.to_date).to_i
      auto_fine=fine
      if days > 0 and auto_fine
        fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}' and created_at <= '#{created_at}'"],:order=>'fine_days ASC')
        fine_amount=fine_rule.is_amount ? fine_rule.fine_amount : (bal*fine_rule.fine_amount)/100 if fine_rule
      end
      fine_amount=0 if financefee.is_paid
      return fine_amount
  end

end
