# To change this template, choose Tools | Templates
# and open the template in the editor.
#require "#{RAILS_ROOT}/vendor/plugins/paperclip/lib/paperclip/interpolations"
module PaperclipCustomInterpolation

  def self.included(base)
    base.extend(Interpolations)
  end

  module Interpolations
    def custom_id_partition custom_id
      ("%09d" % custom_id).scan(/\d{3}/).join("/")
    end
  end
  
end
