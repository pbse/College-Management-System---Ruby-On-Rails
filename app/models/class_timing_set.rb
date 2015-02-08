class ClassTimingSet < ActiveRecord::Base
  has_many :class_timings, :dependent => :destroy
  has_many :time_table_class_timings, :dependent => :destroy
  has_many :batches

  validates_presence_of :name
end
