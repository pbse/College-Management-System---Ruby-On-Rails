#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

require 'fedena_plugin'
require 'paperclip_path_update'
require 'paperclip_custom_interpolation'
namespace :fedena do
  namespace :plugins do
    task :install_all => :environment do
      FedenaPlugin::AVAILABLE_MODULES
      FedenaPlugin::AVAILABLE_MODULES.each do |m|
        Rake::Task["#{m[:name]}:install"].execute
      end
      Rake::Task["db:migrate"].execute
      Rake::Task["fedena:plugins:db:migrate"].execute
      Rake::Task["db:seed"].execute
      Rake::Task["fedena:plugins:db:seed"].execute
      Rake::Task["fedena:records:update"].execute
    end

    namespace :db do

      desc "Migrate the database through scripts in db/migrate and update db/schema.rb by invoking db:schema:dump for each plugin"
      task :migrate => :environment do
        FedenaPlugin::AVAILABLE_MODULES.each do |m|
          ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
          ActiveRecord::Migrator.migrate("vendor/plugins/#{m[:name]}/db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
          Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
        end
      end


      desc 'Load the seed data from db/seeds.rb of each plugin'
      task :seed => :environment do
        FedenaPlugin::AVAILABLE_MODULES.each do |m|
          seed_file = File.join(Rails.root,"vendor/plugins/#{m[:name]}" ,'db', 'seeds.rb')
          load(seed_file) if File.exist?(seed_file)
        end
      end

    end

  end
  

  namespace :data do
    desc "Testing only at present"
    task :update_paths => :environment do
      models = [Student,Employee,ArchivedStudent,ArchivedEmployee,SchoolDetail]
      sub_paths = {
        "ArchivedEmployee" => "public/system/archived_employees",
        "ArchivedStudent" => "public/system/archived_students",
        "Employee" => "public/system/employees",
        "Student" => "public/system/students",
        "SchoolDetail" => "public/system/school_details"
      }
      log = Logger.new("log/paperclip_path_update.log")
      models.each do |model|
        log.debug("#{model}")
        begin
          model.send :include, PaperclipPathUpdate
          model.attachment_definitions.each do |d|
            file_type = "#{d.first}_file_name"
            if model.connection.select_all("select * from #{model.table_name} where #{file_type} is not NULL;").present?
              sub_path1_old = sub_paths["#{model}"]
              sub_path1 = sub_path1_old.gsub("#{model.table_name}","#{model.table_name}_backup")
              File.rename "#{sub_path1_old}", "#{sub_path1}"
              arr = Dir["#{sub_path1}/*/*/"].map {|a| File.basename(a) } unless model == SchoolDetail
              arr = model.connection.select_all("select id from #{model.table_name}").map {|x| x["id"] } if model == SchoolDetail
              arr.each do |arr_l|
                begin
                  rec = model.find_without_school arr_l.to_i
                  file_type = "#{d.first}_file_name"
                  if rec.present? and rec[file_type].present?
                    file = "#{sub_path1}/photos/#{arr_l}/original/#{rec[file_type]}"  unless model == SchoolDetail
                    file = "#{sub_path1}/#{d.first.to_s.pluralize}/#{Paperclip::Interpolations.custom_id_partition arr_l}/original/#{rec[file_type]}"  if model == SchoolDetail
                    if File.exists? file
                      unless rec.update_attribute(d.first.to_sym, File.open(file))
                        log.debug("#{rec.id}----#{rec.errors.full_messages}")
                      end
                    end
                  end
                rescue Exception => err
                  log.debug("#{err.message}")
                  log.debug("------------")
                  log.debug("#{err.backtrace.inspect}")
                end
              end
              sub_path2 = sub_path1.gsub("#{model.table_name}_backup","#{model.table_name}_backup_done")
              File.rename "#{sub_path1}", "#{sub_path2}"
            end
          end
        rescue Exception => e
          log.debug("#{e.message}")
          log.debug("------------")
          log.debug("#{e.backtrace.inspect}")

          puts e
          puts "Failed to complete task! Reverting process"
          sub_path1_old = sub_paths["#{model}"]
          sub_path1 = sub_path1_old.gsub("#{model.table_name}","#{model.table_name}_backup")

          if File.exists? sub_path1
            puts "Restoring old data of #{model.table_name} module"
            if File.exists? sub_path1_old
              FileUtils.rm_r sub_path1_old
            end
            File.rename "#{sub_path1}","#{sub_path1_old}"
          end

        end
      end
    end
  end


  namespace :records do
    desc "Database data update"
    task :update => :environment do
      RecordUpdate.update_normal
      RecordUpdate.update_school
    end    
  end
end
