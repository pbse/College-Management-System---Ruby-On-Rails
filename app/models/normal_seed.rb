class NormalSeed < RecordUpdate
  default_scope :conditions => { :school_id => nil }
end