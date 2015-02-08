module ActiveRecordDateValidator
  def self.included(base)
    base.instance_eval do
      validate :validate_date_range
    end
  end

  def validate_date_range
    date_columns = self.class.columns.select{|column| (column.type == :date and column.sql_type == "date")}.map{|column| column.name.to_sym}
    datetime_columns = self.class.columns.select{|column| (column.type == :datetime and column.sql_type == "datetime")}.map{|column| column.name.to_sym}
    date_columns.each do |date_column|
      self[date_column] = Date.parse(self[date_column].to_s) rescue nil
      if (self[date_column].present? and (self[date_column].to_date < "1000-01-01".to_date or self[date_column].to_date > "9999-12-31".to_date))
        self.errors.add(date_column, :date_range_error)
      end
    end
    
    datetime_columns.each do |datetime_column|
      self[datetime_column] = DateTime.parse(self[datetime_column].to_s) rescue nil
      if (self[datetime_column].present? and (self[datetime_column] < "1000-01-01 00:00:00".to_datetime or self[datetime_column] > "9999-12-31 23:59:59".to_datetime))
        self.errors.add(datetime_column, :datetime_range_error)
      end
    end
  end
end

ActiveRecord::Base.instance_eval{ include ActiveRecordDateValidator}