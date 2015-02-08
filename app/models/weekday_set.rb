class WeekdaySet < ActiveRecord::Base
  has_many :batches
  has_many :time_table_weekdays
  has_many :weekday_sets_weekdays,:dependent => :destroy

  alias_method :weekdays,:weekday_sets_weekdays

  named_scope :default ,:first

  WEEKDAYS = {
    "0" => t("sunday"),
    "1" => t("monday"),
    "2" => t("tuesday"),
    "3" => t("wednesday"),
    "4" => t("thursday"),
    "5" => t("friday"),
    "6" => t("saturday")
  }

  def self.default_weekdays
    default_weekdays = ActiveSupport::OrderedHash.new
    WEEKDAYS.sort.each do |weekday|
      default_weekdays[weekday.first] = weekday.last
    end
    default_weekdays
  end
  
  def weekday_ids
    weekdays.map(&:weekday_id)
  end

  def weekday_ids=(ids = Array.new)
    if (ids.blank? or ids.nil?)
      weekdays.destroy_all
    else
      weekdays.destroy_all
      ids.map{|id| weekdays.build(:weekday_id => id)}
      save
    end
  end

  def self.weekday_name(weekday_no)
    I18n.translate default_weekdays[weekday_no.to_s].downcase
  end
end
