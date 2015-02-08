class SubjectAmount < ActiveRecord::Base
  belongs_to :course

  validates_uniqueness_of :code,:scope => :course_id
  validates_presence_of :course_id,:amount,:code
  validates_numericality_of :amount,:greater_than_or_equal_to =>0 ,:allow_blank=>true
end
