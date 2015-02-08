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

namespace :fedena do
  desc 'Flushing all session data , which has not been updated since past week'
  task :cleanup_session => :environment do
    CGI::Session::ActiveRecordStore::FastSessions.delete_old!
    optimize_query = "alter table #{CGI::Session::ActiveRecordStore::FastSessions.table_name} ENGINE=INNODB"
    CGI::Session::ActiveRecordStore::FastSessions.connection.execute(optimize_query)
  end
end