FinanceFeeCategory.find(:all,:group=>'concat(name,description)',:conditions=>"is_deleted=#{false} and is_master=#{true} and batch_id is not NULL").each do |a|
  FinanceFeeCategory.find(:all,:conditions=>"id<>'#{a.id}' and name='#{a.name}' and is_deleted='#{false}' and description='#{a.description}' and batch_id is not NULL").each do |b|
     FinanceFeeParticular.connection.execute("UPDATE `finance_fee_particulars` SET `finance_fee_category_id` = '#{a.id}' WHERE `finance_fee_category_id`=#{b.id} and `batch_id`=#{b.batch_id} and `is_deleted`=#{false};")
     FeeDiscount.connection.execute("UPDATE `fee_discounts` SET `finance_fee_category_id` = '#{a.id}' WHERE `finance_fee_category_id`=#{b.id} and `batch_id`=#{b.batch_id} and `is_deleted`=#{false};")
    end
end