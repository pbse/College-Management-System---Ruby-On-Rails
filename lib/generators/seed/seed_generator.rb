class SeedGenerator < Rails::Generator::NamedBase
  attr_accessor :plugin, :name, :school

  def initialize(runtime_args, runtime_options = {})
    super
    @name = runtime_args.first
    @school = false
    @plugin = "core"

    runtime_args[1..-1].each do |arg|
      if arg.include?("fedena_")
        @plugin=arg
      end
      if arg.to_s.downcase=="school"
        @school = true
      end
    end
  end

  def manifest
    record do |m|
      dir_exist=true
      unless plugin=="core"
        dir_exist=File.directory?("vendor/plugins/#{plugin}")
      end
      if dir_exist
        path=""
        file_name="#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_#{name.underscore}.rb"
        if plugin=="core"
          path="db/seeds/"
        else
          path="vendor/plugins/#{plugin}/db/seeds/"
        end
        if school
          path+="school/"
        end
        FileUtils.mkdir_p(path)
        file_path=path+file_name
        
        File.open(file_path,"w")
        p "================ File created"
        p "#{file_path}"
      else
        p "No such file or directory - vendor/plugins/#{plugin}"
      end
    end
  end
end