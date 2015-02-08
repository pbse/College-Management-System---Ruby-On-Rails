module Delayed
  module Manager
    class Local
      def initialize(options={})
      end

      def qty
        if pid=current_worker
          Rush::Box.new.processes.filter(:parent_pid=>pid,:cmdline => /rake jobs:work/).size
        else
          0
        end
      end

      def scale_up
        pid = Rush::Box.new[RAILS_ROOT].bash "rake jobs:work", :background => true
        make_pid_file(pid.pid)
        pid
      end

      def scale_down
        $exit = true
      end

      def make_pid_file(cpid)
        Dir.mkdir('tmp') unless File.exists?('tmp') && File.directory?('tmp')
        File.open('tmp/delayed_job.pid','w') do |f|
          f.puts "#{cpid}"
        end
      end
          
      def current_worker
        pid = if File.exists?('tmp/delayed_job.pid')
          File.read('tmp/delayed_job.pid')
        end
        return pid.to_i if pid.to_i > 0
      end
    end
  end
end