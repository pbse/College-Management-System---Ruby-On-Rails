class RedactorController < ApplicationController
      
  def upload
    redactor_upload = RedactorUpload.new
    redactor_upload.image = params[:file]  
    if redactor_upload.save
      render :json => {:filelink=>"#{redactor_upload.image.url}",:id=>redactor_upload.id}.to_json
    else
      render :json => {:error => "failed to upload",:error_message => redactor_upload.errors.full_messages }.to_json
    end
  end

  def post_upload
    s3_object_key = params[:key]
    policy = RedactorS3Helper.new
    policy.make_s3_connection
    s3_object = policy.fetch_s3_object(s3_object_key)
    redactor_upload = RedactorUpload.new(
      :name => "#{s3_object.key.split('/').last}",
      :image_file_name => "#{s3_object.key.split('/').last}",
      :image_file_size => "#{s3_object.size}"
    )
    
    if(redactor_upload.save)
      s3_new_object_key = redactor_upload.image.path
      filelink = policy.rename(s3_object_key,s3_new_object_key)
      render :json => {:filelink => filelink,:id=>redactor_upload.id}.to_json
    else
      render :json => {:error => "failed to upload",:error_message => redactor_upload.errors.full_messages }.to_json
    end
  end

end
