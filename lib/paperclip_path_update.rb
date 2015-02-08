module PaperclipPathUpdate
   def self.included (base)
     base.class_eval do
       extend ClassMethods
     end
   end
#  def self.included(base)
#    base.send :extend, ClassMethods
#    unless base.method_defined? :after_initialize
#
#    end
#    base.alias_method_chain :after_initialize, :escape_school_id
#    if base.method_defined? :after_initialize
#      base.class_eval do
#        def after_initialize_with_school_id
#          after_initialize_without_school_id
#        end
#      end
#    end
#  end
#
#  def after_initialize_with_escape_school_id
#    if defined? :after_initialize_without_school_id
##      puts 'hhkhh'
##      after_initialize_without_school_id
#    else
#      after_initialize_without_escape_school_id
#    end
#  end
  
  module ClassMethods

    def find_without_school id
      rec = connection.select_one("select * from #{table_name} where id = #{id};")
#      p "#{table_name}-#{id}-#{rec.present?}-#{rec.keys.include?("school_id")}-#{defined? MultiSchool}"
      if rec.present? and rec.keys.include?("school_id") and defined? MultiSchool
        MultiSchool.current_school = School.find rec["school_id"]
      end
      send :instantiate,rec unless rec.nil?
    end
    
  end
   
end
