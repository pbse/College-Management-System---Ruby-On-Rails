module Api::TimetablesHelper
  def weekday_name(index)
    day = ["#{t('sunday')}", "#{t('monday')}", "#{t('tuesday')}", "#{t('wednesday')}", "#{t('thursday')}", "#{t('friday')}", "#{t('saturday')}"]
    day[index.to_i]
  end
end
