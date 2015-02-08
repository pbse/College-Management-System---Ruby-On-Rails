class RecordUpdate < ActiveRecord::Base

  validates_uniqueness_of :file_name, :scope=> [:school_id]

  def self.update_normal
    update_normal_run
  end

  def self.update_school
    update_school_run(nil)
  end

  class << self
    def update_normal_run
      #core
      RecordUpdate.transaction do
        records_update_files = Dir["#{Rails.root}/db/seeds/*.rb"]
        records_update_files.each do |r_u|
          if confirmed_task(File.basename(r_u), nil)
            begin
              load(r_u)
              p "===========#{File.basename(r_u)} Finished"
            rescue Exception => e
              p "===========#{File.basename(r_u)} Reverted"
              p "#{e}"
              revert_confirmed_task(File.basename(r_u), nil)
            end
          end
        end
        #plugins
        FedenaPlugin::AVAILABLE_MODULES.each do |m|
          plugin_records_update_files = Dir["#{Rails.root}/vendor/plugins/#{m[:name]}/db/seeds/*.rb"]
          plugin_records_update_files.each do |r_u|
            if confirmed_task(File.basename(r_u), nil)
              begin
                load(r_u)
                p "===========#{File.basename(r_u)} Finished"
              rescue Exception => e
                p "===========#{File.basename(r_u)} Reverted"
                p "#{e}"
                revert_confirmed_task(File.basename(r_u), nil)
              end
            end
          end
        end
      end
    end

    def update_school_run(s_id)
      #core
      RecordUpdate.transaction do
        records_update_files = Dir["#{Rails.root}/db/seeds/school/*.rb"]
        records_update_files.each do |r_u|
          if confirmed_task(File.basename(r_u), s_id)
            begin
              load(r_u)
              if s_id.nil?
                p "===========#{File.basename(r_u)} Finished"
              else
                p "===========#{File.basename(r_u)} Finished for school #{s_id}"
              end
            rescue Exception => e
              if s_id.nil?
                p "===========#{File.basename(r_u)} Reverted"
              else
                p "===========#{File.basename(r_u)} Reverted for school #{s_id}"
              end
              p "#{e}"
              revert_confirmed_task(File.basename(r_u), s_id)
            end
          end
        end
        #plugins
        FedenaPlugin::AVAILABLE_MODULES.each do |m|
          plugin_records_update_files = Dir["#{Rails.root}/vendor/plugins/#{m[:name]}/db/seeds/school/*.rb"]
          plugin_records_update_files.each do |r_u|
            if confirmed_task(File.basename(r_u), s_id)
              begin
                load(r_u)
                if s_id.nil?
                  p "===========#{File.basename(r_u)} Finished"
                else
                  p "===========#{File.basename(r_u)} Finished for school #{s_id}"
                end
              rescue Exception => e
                if s_id.nil?
                  p "===========#{File.basename(r_u)} Reverted"
                else
                  p "===========#{File.basename(r_u)} Reverted for school #{s_id}"
                end
                p "#{e}"
                revert_confirmed_task(File.basename(r_u), s_id)
              end
            end
          end
        end
      end
    end

    def confirmed_task(file_name, school_id)
      record_update = RecordUpdate.new(:file_name=>file_name, :school_id=>school_id)
      return record_update.save
    end

    def revert_confirmed_task(file_name, school_id)
      record_update = RecordUpdate.find(:first, :conditions=>{:file_name=>file_name, :school_id=>school_id})
      record_update.destroy if record_update.present?
    end
  end
end