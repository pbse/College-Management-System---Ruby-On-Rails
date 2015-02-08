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
class CceExamCategory < ActiveRecord::Base
  has_many                :cce_weightages
  has_many :exam_groups 
  has_many                :fa_groups
  validates_presence_of     :name
  validates_presence_of     :desc

  before_destroy :check_dependencies

  private

  def check_dependencies
    !(cce_weightages.present? or exam_groups.present? or fa_groups.present?)
  end

end
