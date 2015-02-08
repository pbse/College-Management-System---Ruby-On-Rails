class Fine < ActiveRecord::Base
  belongs_to :user
  has_many :finance_fee_collections
  has_many :fine_rules
  validates_presence_of :name
  validates_uniqueness_of :name, :scope=> [:is_deleted],:if=> 'is_deleted == false'
  validates_format_of :name,:with=>/^\S.*\S$/i,:message => :should_not_contain_white_spaces_at_the_beginning_and_end
  
  accepts_nested_attributes_for :fine_rules,:allow_destroy => true

  named_scope :active ,{:conditions=>{:is_deleted=>false}}
end
