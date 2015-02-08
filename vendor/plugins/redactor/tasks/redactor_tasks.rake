namespace :redactor do
  desc "Install Redactor Module"
  task :install do
    system "rsync -ruv --exclude=.svn vendor/plugins/redactor/public ."
  end
end