Event.find_in_batches(:batch_size=>500) do |batch|
  batch.each do |event|
    if event.origin.nil? and event.origin_type.present?
      event.destroy
    elsif event.origin_type=="HostelFeeCollection"
      if event.origin.is_deleted==true
        event.destroy
      end
    end
  end
end