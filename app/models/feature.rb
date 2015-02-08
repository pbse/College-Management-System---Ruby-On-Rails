class Feature < ActiveRecord::Base
  validates_uniqueness_of :feature_key
end
