Array.send :include,WillPaginateExtension::Array
Hash.send :include,WillPaginateExtension::Hash
Paperclip::Interpolations.send :include,PaperclipCustomInterpolation
Hash.instance_eval do
  def from_xml(*args)
    super(*args).with_indifferent_access
  end
end
Paperclip.interpolates :timestamp do |attachment,style|
  attachment.instance.updated_at.present? ? attachment.instance.updated_at.strftime('%Y%m%d%H%m%S') : nil
end
Paperclip.interpolates :attachment_fullname do |attachment,style|
  file_name=attachment.name.to_s + "_file_name"
  CGI::escape(attachment.instance.send(file_name))
end