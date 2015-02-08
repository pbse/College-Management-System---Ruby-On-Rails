# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
class PaperclipAttachment
  def self.call(env)
    begin
      paperclip_attachment = is_paperclip_attachment_request(env["PATH_INFO"])
      if paperclip_attachment
        paperclip_attachment_return(env)
      else
        [404, {"Content-Type" => "text/html"}, ["Not Found"]]
      end
    rescue Exception => e
      log = Logger.new("log/paperclip_request_error.log")
      log.debug("\n\n")
      log.debug("#{env["PATH_INFO"]}")
      log.debug("#{e}")
      return [500, {"Content-Type" => "text/html"}, ["Sorry. Something Went Wrong."]]
    end
  end

  class << self
    def is_paperclip_attachment_request(request_path)
      url_path_ar = request_path.split("/") if request_path
      if url_path_ar and (url_path_ar.length == 6) and (url_path_ar[1]=="uploads") and (url_path_ar[3].to_i.to_s==url_path_ar[3].to_s)
        return true
      end
      return false
    end

    def paperclip_attachment_return(env)
      request_path=env["PATH_INFO"]
      request_host=env["SERVER_NAME"]
      url_path_ar = request_path.split("/")
      begin
        if url_path_ar[2]=="school_details" or env['rack.session'][:user_id].present?
          model = url_path_ar[2].classify.constantize
          attachment_name = url_path_ar[4].classify.downcase
          record = model.find(url_path_ar[3])
          file_attachment = record.send(attachment_name)
          file_open = File.open(file_attachment.path(:original))
          cache_expire = 60*60*24*365
          return [200, {"Content-Type" => file_attachment.content_type, "Etag" => "'#{record.updated_at.strftime('%Y%m%d%H%m%S')}'", "Cache-Control" => "private", "Connection" => "keep-alive", "Expires" => Time.at(Time.now.to_i + cache_expire).strftime("%a, %d %b %Y %H:%m:%S GMT")}, [file_open.read]]
        else
          return [401, {"Content-Type" => "text/html"}, ["Unauthorized Access."]]
        end
      rescue Exception => e
        log = Logger.new("log/paperclip_request_error.log")
        log.debug("\n\n")
        log.debug("#{request_path}")
        log.debug("#{e}")
        return [500, {"Content-Type" => "text/html"}, ["Sorry. Something Went Wrong."]]
      end
    end
  end
end
