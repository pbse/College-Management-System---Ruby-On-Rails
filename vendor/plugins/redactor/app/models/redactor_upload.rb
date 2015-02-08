class RedactorUpload < ActiveRecord::Base

  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']

  has_attached_file :image,
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:id_partition/:attachment/:attachment_fullname"

  
  validates_attachment_size :image, :less_than => 5.megabytes, :message => 'Image size must be less than 5Mb'
  validates_attachment_content_type :image, :content_type =>VALID_IMAGE_TYPES,
    :message=>'Image can only be GIF, PNG, JPG'

  before_create :set_content_type

  def set_content_type
    if(File.exist? File.join(::Rails.root, 'config', 'amazon_s3.yml'))
      type = self.name.split('.').last
      if(type.present?)
        self.image_content_type = "image/#{type}"
      end
    end
  end

  def self.delete_redactors(ids)
    id_array = ids.split(',')
    self.destroy(id_array)
  end

  def self.update_redactors(update_redactor_ids,delete_redactor_ids)
    delete_redactors(delete_redactor_ids) unless delete_redactor_ids.nil?
    unless update_redactor_ids.nil?
      ids = update_redactor_ids.split(',')
      ids.each do |redactor_id|
        RedactorUpload.update(redactor_id, {:is_used => true})
      end
    end
  end

  def self.delete_after_create(search_embedding)
    regex = /uploads\/([0-9\/]*)\/images/
    redactors_not_used = search_embedding.scan(regex).flatten.collect {|x| x.split('/').join('').to_i}
    redactors_not_used.each do |redactor_id|
      self.update(redactor_id,{:is_used=>false})
    end
  end

  ## merge s3 attributes if s3 settings file is detected as a check for s3 enabled environment
  if(File.exist? File.join(::Rails.root, 'config', 'amazon_s3.yml'))
    {
      :storage=>:s3,
      :s3_credentials=>{
        :bucket => Config.bucket_public,
        :access_key_id => Config.access_key_id,
        :secret_access_key => Config.secret_access_key,
      },
      :s3_host_alias=> Config.cloudfront_public,
      :url => ':s3_alias_url',
      :s3_permissions=>:public_read

    }.each do |k,v|
      Paperclip::Attachment.default_options.merge! k=>v
    end
  end
end
