

FinanceFeeCategory.find(:all,:group=>'concat(name,description)',:conditions=>{:is_deleted=>false,:is_master=>true}).each do |a|
  FinanceFeeCategory.find(:all,:conditions=>{:name=>a.name,:is_deleted=>false,:description=>a.description}).each do |b|
    CategoryBatch.create(:finance_fee_category_id=>a.id,:batch_id=>b.batch_id)
  end
end


FinanceFeeParticular.find_in_batches(:batch_size=>500) do |batch|
  batch.each do |fee_particular|
    batch_id=fee_particular.finance_fee_category.try('batch_id')
    s=Student.find_by_admission_no(fee_particular.admission_no).present? ? Student.find_by_admission_no(fee_particular.admission_no).id : ArchivedStudent.find_by_admission_no(fee_particular.admission_no).try('former_id') if fee_particular.admission_no
    FinanceFeeParticular.connection.execute("UPDATE `finance_fee_particulars` SET `batch_id` = '#{batch_id}' WHERE `id` = #{fee_particular.id};")
    if fee_particular.student_category.nil? and fee_particular.admission_no.present?
      FinanceFeeParticular.connection.execute("UPDATE `finance_fee_particulars` SET `receiver_id` = '#{s}',`receiver_type`='Student' WHERE `id` = #{fee_particular.id};")
    elsif fee_particular.student_category.present? and fee_particular.admission_no.nil?
      FinanceFeeParticular.connection.execute("UPDATE `finance_fee_particulars` SET `receiver_id` = '#{fee_particular.student_category_id}',`receiver_type`='StudentCategory' WHERE `id` = #{fee_particular.id};")
    else
      FinanceFeeParticular.connection.execute("UPDATE `finance_fee_particulars` SET `receiver_id` = '#{batch_id}',`receiver_type`='Batch' WHERE `id` = #{fee_particular.id};")
    end
  end
end


FinanceFeeCollection.find(:all,:conditions=>{:is_deleted=>false}).each do |a|
  FeeCollectionBatch.connection.execute("INSERT INTO `fee_collection_batches` SET `finance_fee_collection_id` = '#{a.id}',`batch_id`='#{a.batch_id}',created_at='#{a.created_at}',updated_at='#{a.updated_at}'")
    

end

FeeDiscount.update_all("receiver_type= 'Student'","type = 'StudentFeeDiscount'")
FeeDiscount.update_all("receiver_type= 'StudentCategory'","type = 'StudentCategoryFeeDiscount'")
FeeDiscount.update_all("receiver_type= 'Batch'","type = 'BatchFeeDiscount'")
FeeDiscount.update_all("batch_id= receiver_id","receiver_type = 'Batch'")
FeeDiscount.find(:all,:conditions=>["type<>'BatchFeeDiscount'"]).each do |fd|
  FeeDiscount.connection.execute("UPDATE `fee_discounts` SET `batch_id` = '#{fd.finance_fee_category.try('batch_id')}' WHERE `id` = #{fd.id};")
end

FinanceFee.find(:all,:conditions=>["transaction_id !=''"]).each do |fft|
  fft.transaction_id.split(",").each do |transaction_id|
    FeeTransaction.create(:finance_fee_id=>fft.id,:finance_transaction_id=>transaction_id)
  end
end

FeeCollectionDiscount.find_in_batches(:batch_size=>500) do |discount_batch|
  discount_batch.each do |discount|
    dis=FeeDiscount.find(:first,:conditions=>{:finance_fee_category_id=>discount.finance_fee_collection.try('fee_category_id'),:name=>discount.name})

    unless dis
      attr=discount.attributes
      attr.delete "finance_fee_collection_id"
      dis=FeeDiscount.new(attr)
      dis.finance_fee_category_id=discount.finance_fee_collection.try('fee_category_id')
      dis.receiver_type=discount.type.gsub("FeeCollectionDiscount","")
      dis.batch_id=discount.finance_fee_collection.try('batch_id')
      dis.is_deleted=true
      dis.save(false)
    end
    CollectionDiscount.create(:fee_discount_id=>dis.id,:finance_fee_collection_id=>discount.finance_fee_collection_id) if dis
  end
end
FeeCollectionParticular.find_in_batches(:batch_size=>500) do |particular_batch|
  particular_batch.each do |particular|
    part=FinanceFeeParticular.find(:first,:conditions=>{:finance_fee_category_id=>particular.finance_fee_collection.try('fee_category_id'),:name=>particular.name,:amount=>particular.amount,:description=>particular.description,:student_category_id=>particular.student_category_id,:admission_no=>particular.admission_no,:student_id=>particular.student_id})
    unless part
      attr=particular.attributes
      attr.delete "finance_fee_collection_id"
      part=FinanceFeeParticular.new(attr)
      part.finance_fee_category_id=particular.finance_fee_collection.try('fee_category_id')
      batch_id=particular.finance_fee_collection.try('fee_category').try('batch_id')
      part.batch_id=batch_id
      if particular.student_category.nil? and particular.admission_no.present?
        part.receiver_type="Student"
        part.receiver_id=Student.find_by_admission_no(particular.admission_no).present? ? Student.find_by_admission_no(particular.admission_no).id : ArchivedStudent.find_by_admission_no(particular.admission_no).former_id
      elsif particular.student_category.present? and particular.admission_no.nil?
        part.receiver_type="StudentCategory"
        part.receiver_id=particular.student_category_id
      else
        part.receiver_type="Batch"
        part.receiver_id=batch_id
      end
      part.is_deleted=true
      part.save
    end
    CollectionParticular.create(:finance_fee_particular_id=>part.id,:finance_fee_collection_id=>particular.finance_fee_collection_id) if part
  end
end

fee=FinanceTransactionCategory.find_by_name("Fee")
FinanceTransaction.find(:all,:conditions=>["category_id='#{fee.id}'"]).each do |ft|
  ft.update_attributes(:batch_id=>ft.student_payee.batch_id) if ft.student_payee
end
 

FinanceFee.find_in_batches(:batch_size=>500) do|batch|
  batch.each do |finance_fee|

    if finance_fee.student.present?
      ffc=finance_fee.finance_fee_collection
#      batchstudent=BatchStudent.find(:first,:conditions=>"student_id='#{finance_fee.student_id}' and created_at > '#{ffc.created_at}'")
#      if batchstudent.present?
#        batch_id=batchstudent.batch_id
#      else
#        batch_id=finance_fee.student.batch_id
#      end
      finance_fee.update_attributes(:batch_id=>ffc.batch_id) if ffc.batch_id.present?
    end
  end
end


