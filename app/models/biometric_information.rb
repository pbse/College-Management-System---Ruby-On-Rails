  class BiometricInformation < ActiveRecord::Base
  belongs_to :user
  validates_uniqueness_of :user_id
  validates_uniqueness_of :biometric_id,:allow_blank => true,:allow_nil => true
end
