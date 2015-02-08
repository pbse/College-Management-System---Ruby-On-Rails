class FedenaPrecision

  def self.set_and_modify_precision value
    if defined? value and value != '' and !value.nil?
      precision_count = Configuration.get_config_value('PrecisionCount')
      precision = precision_count.to_i < 2 ? 2 : precision_count.to_i
      value = sprintf("%0.#{precision}f",value)#temp.join('.').to_f
      value
    else
      return
    end
  end

end