require 'multi_json'
require 'aws/s3'   if (File.exist? File.join(::Rails.root, 'config', 'amazon_s3.yml'))
class RedactorS3Helper
  attr_reader :options

  def initialize(_options = {})
    @options = {
      :acl => Config.acl,
      :max_file_size => _options[:max_file_size] || Config.max_file_size || 524288000,
      :bucket => Config.bucket_public,
      :file_types => _options[:file_types],
    }.merge(_options)
    @options
  end

  def fetch_s3_object s3_object_key
    s3_object = AWS::S3::S3Object.find(s3_object_key,Config.bucket_public)
    s3_object
  end

  def make_s3_connection
    AWS::S3::Base.establish_connection!(
      :access_key_id => Config.access_key_id,
      :secret_access_key => Config.secret_access_key
    )
  end

  def rename(s3_object_key,s3_new_object_key)
    response_code = AWS::S3::S3Object.copy(s3_object_key,s3_new_object_key,Config.bucket_public,{:copy_acl => true})
    AWS::S3::S3Object.delete(s3_object_key,Config.bucket_public)
    
    if(response_code.response.code == '200')
      "#{Config.cloudfront_public}/#{s3_new_object_key}"
    end
  end

  # generate the policy document that amazon is expecting.
  def policy_document #redactor_upload, expires_after
  
      @policy_document ||=
        Base64.encode64(
        MultiJson.dump(
          {
            :expiration => 10.hours.from_now.utc.iso8601(3),
            :conditions => [
              { :bucket => Config.bucket_public },
              { :success_action_redirect => "#{Fedena.hostname}/redactor/post_upload"},
              ["starts-with", "$key", ""],
              ["starts-with", "$success_action_redirect", ""],
              { :acl => "public-read"},
              ["content-length-range", 0, options[:max_file_size]]
            ]
          }
        )
      ).gsub(/\n/, '')
  end

  # sign our request by Base64 encoding the policy document.
  def upload_signature

    upload_sign =
      Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest::SHA1.new,
        Config.secret_access_key,
        policy_document
      )
    ).gsub(/\n/, '')
  end

end

module Config
  # this allows us to lazily instantiate the configuration by reading it in when it needs to be accessed
  class << self
    # if a method is called on the class, attempt to look it up in the config array
    def method_missing(meth, *args, &block)
      if args.empty? && block.nil?
        config[meth.to_s]
      else
        super
      end
    end

    private

    def config

      @config ||= YAML.load(ERB.new(File.read(File.join(::Rails.root, 'config', 'amazon_s3.yml'))).result)[::Rails.env]
    rescue
      warn('WARNING: s3_cors_fileupload gem was unable to locate a configuration file in config/amazon_s3.yml and may not ' +
          'be able to function properly.  Please run `rails generate s3_cors_upload:install` before proceeding.')
      {}
    end
  end
end