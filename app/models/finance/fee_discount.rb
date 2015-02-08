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

class FeeDiscount < ActiveRecord::Base

  belongs_to :finance_fee_category
  validates_presence_of :name, :receiver_id,:receiver_type
  validates_numericality_of :discount,:allow_blank=>true
  belongs_to :receiver,:polymorphic=>true
  has_many   :finance_fee_collections,:through=>:collection_discounts
  has_many   :collection_discounts
  belongs_to :batch
  belongs_to :finance_fee_particular
  validates_uniqueness_of :name,:scope=>[:batch_id,:finance_fee_category_id]
  validates_inclusion_of :discount, :in => 0..100,:unless=>:is_amount,:message=>:amount_in_percentage_cant_exceed_100,:allow_blank=>true
#  after_create :update_category,:if=>Proc.new{Configuration.find_by_config_key("SetupDiscountReceiverType").present? and Configuration.find_by_config_key("SetupCollectionDiscount").present?}
  before_update :collection_exist

  def validate

      ds_id=id.to_i
      particulars=finance_fee_category.fee_particulars.all(:group=>["receiver_type,receiver_id"],:select=>("sum(finance_fee_particulars.amount) as pamt,receiver_type,receiver_id"),:conditions=>"batch_id='#{batch_id}' and is_deleted=false")

      if receiver_type=='StudentCategory'
        students=batch.students.all(:conditions=>"student_category_id='#{receiver_id}'").collect(&:id)
        part_amt= particulars.select{|s| (s.receiver_type=='StudentCategory' and s.receiver_id==receiver_id) or (s.receiver_type=='Student' and students.include?(s.receiver_id)) or (s.receiver_type=='Batch' and s.receiver_id==batch_id)}.map{|s| s.pamt.to_f}.sum
      elsif receiver_type=='Student'
        part_amt= particulars.select{|s| (s.receiver_type==receiver_type.to_s and s.receiver_id==receiver_id) or (s.receiver_type=='StudentCategory' and s.receiver_id==receiver.student_category_id) or (s.receiver_type=='Batch' and s.receiver_id==batch_id)}.map{|s| s.pamt.to_f}.sum
      else
       part_amt= particulars.select{|s| (s.receiver_type=='Batch' and s.receiver_id==batch_id)}.map{|s| s.pamt.to_f}.sum
      end


      discounts=finance_fee_category.fee_discounts.all(:group=>["receiver_type,receiver_id"],:select=>("sum(#{part_amt}*fee_discounts.discount/IF(is_amount=1,#{part_amt},100)) as damt,receiver_type,receiver_id"),:conditions=>"batch_id='#{batch_id}' and id<>#{ds_id} and is_deleted=#{false}")
      if receiver_type=='StudentCategory'
        students=batch.students.all(:conditions=>"student_category_id='#{receiver_id}'").collect(&:id)
        discount_amt= discounts.select{|s| (s.receiver_type==receiver_type.to_s and s.receiver_id==receiver_id) or (s.receiver_type=='Student' and students.include? s.receiver_id) or (s.receiver_type=='Batch' and s.receiver_id==batch_id)}.map{|s| s.damt.to_f}.sum
        disc_amt=nil
      elsif receiver_type=='Student'
        disc_amt=nil
        discount_amt= discounts.select{|s| (s.receiver_type==receiver_type.to_s and s.receiver_id==receiver_id) or (s.receiver_type=='StudentCategory' and s.receiver_id==receiver.student_category_id) or (s.receiver_type=='Batch' and s.receiver_id==batch_id)}.map{|s| s.damt.to_f}.sum
      else
        discs=[]
        sc_part_amt= particulars.select{|s| (s.receiver_type=='StudentCategory') or (s.receiver_type=='Batch' and s.receiver_id==batch_id)}.map{|s| s.pamt.to_f}.sum
        discs=finance_fee_category.fee_discounts.all(:group=>["receiver_type,receiver_id"],:select=>("#{sc_part_amt}-sum(#{sc_part_amt}*fee_discounts.discount/IF(is_amount=1,#{sc_part_amt},100)) as damt"),:conditions=>"receiver_type='StudentCategory' and batch_id='#{batch_id}' and id<>#{ds_id} and is_deleted=#{false}").map{|a| a.damt.to_f}
        s_part_amt= particulars.select{|s|  (s.receiver_type=='Student') or (s.receiver_type=='Batch' and s.receiver_id==batch_id)}.map{|s| s.pamt.to_f}.sum
        discs<<finance_fee_category.fee_discounts.all(:group=>["receiver_type,receiver_id"],:select=>("#{s_part_amt}-sum(#{s_part_amt}*fee_discounts.discount/IF(is_amount=1,#{s_part_amt},100)) as damt"),:conditions=>"receiver_type='Student' and batch_id='#{batch_id}' and id<>#{ds_id} and is_deleted=#{false}").map{|a| a.damt.to_f}.first
        b_part_amt= discounts.select{|s| (s.receiver_type=='Batch' and s.receiver_id==batch_id)}.map{|s| s.damt.to_f}.sum
        discs<<finance_fee_category.fee_discounts.all(:group=>["receiver_type,receiver_id"],:select=>("#{b_part_amt}-sum(#{b_part_amt}*fee_discounts.discount/IF(is_amount=1,#{b_part_amt},100)) as damt"),:conditions=>"receiver_type='Batch' and batch_id='#{batch_id}' and id<>#{ds_id} and is_deleted=#{false}").map{|a| a.damt.to_f}.first
        discs=discs.compact
        discount_amt= discounts.select{|s| (s.receiver_type=='Batch' and s.receiver_id==batch_id)}.map{|s| s.damt.to_f}.sum
        disc_amt=discs.min
      end

      tot_amt=part_amt-discount_amt

      # part_amt=fee_particular.amount.to_f if fee_particular.present?
      tot_disc_amt=part_amt*discount.to_f/(is_amount?? part_amt : 100)
        disc_amt=disc_amt.nil?? tot_disc_amt : discs.min
      if(tot_disc_amt.to_f > tot_amt.to_f) or (tot_disc_amt.to_f > disc_amt.to_f)
        errors.add_to_base(t('discount_cannot_be_greater_than_total_amount'))
      elsif tot_disc_amt.to_f <= 0.0
        errors.add_to_base(t('discount_cannot_be_zero'))
      end
      # end

  end
  def total_payable
    payable = finance_fee_category.fee_particulars.active.map(&:amount).compact.flatten.sum
    payable
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
#  def self.max_discount(ff,id)
#    category_discs=FeeDiscount.find(:all,:joins=>"INNER JOIN batches on batches.id=fee_discounts.batch_id INNER JOIN students on students.student_category_id=fee_discounts.receiver_id",:group=>["students.id,batches.id"],:select=>["sum((fee_discounts.discount*'#{ff.amount.to_f}')/(IF (fee_discounts.is_amount=1,'#{ff.amount.to_f}',100))) as cat,students.id" ],:conditions=>"fee_discounts.finance_fee_particular_id='#{ff.id}' and fee_discounts.receiver_type='StudentCategory' and fee_discounts.id<>#{id} and batches.id=#{ff.batch_id}")
#    batch_discs=FeeDiscount.find(:all,:joins=>"INNER JOIN batches on batches.id=fee_discounts.batch_id INNER JOIN students on students.batch_id=batches.id",:group=>["students.id,batches.id"],:select=>["sum((fee_discounts.discount*'#{ff.amount.to_f}')/(IF (fee_discounts.is_amount=1,'#{ff.amount.to_f}',100))) as cat,students.id" ],:conditions=>"fee_discounts.finance_fee_particular_id='#{ff.id}' and fee_discounts.receiver_type='Batch' and fee_discounts.id<>#{id} and batches.id=#{ff.batch_id}")
#    student_discounts=FeeDiscount.find(:all,:joins=>"INNER JOIN batches on batches.id=fee_discounts.batch_id INNER JOIN students on students.id=fee_discounts.receiver_id",:group=>["students.id,batches.id"],:select=>["sum((fee_discounts.discount*'#{ff.amount.to_f}')/(IF (fee_discounts.is_amount=1,'#{ff.amount.to_f}',100))) as cat,students.id" ],:conditions=>"fee_discounts.finance_fee_particular_id='#{ff.id}' and fee_discounts.receiver_type='Student' and fee_discounts.id<>#{id} and batches.id=#{ff.batch_id}")
#
#    all_discs= (category_discs+batch_discs+student_discounts).group_by(&:id)
#    all_discs.each{|k,v| all_discs[k]=v.sum{|s| s.cat.to_f}}
#    return all_discs
#  end

#  def fee_category
#    cat=FinanceFeeCategory.find_by_name_and_batch_id(finance_fee_category.name,batch_id)
#    cat.present?? cat : finance_fee_category
#  end

  def collection_exist
    unless is_deleted_changed?
    collection_ids=finance_fee_category.fee_collections.collect(&:id)
    if CollectionDiscount.find_by_fee_discount_id_and_finance_fee_collection_id(id,collection_ids)
    errors.add_to_base(t('collection_exists_for_this_category_cant_edit_this_discount'))
      return false
    else
      return true
    end
  end
  end

#  private
#
#  def update_category
#    update_attributes(:finance_fee_category_id=>fee_category.id)
#  end

end
