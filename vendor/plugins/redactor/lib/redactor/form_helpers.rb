# To change this template, choose Tools | Templates
# and open the template in the editor.

module Redactor::FormHelpers
  def redactor(object_name, field, options = {})

    id = redactor_element_id(object_name, field)
    @latex = options[:latex] if options[:latex].present?
    s3_present = File.exist? File.join(::Rails.root, 'config', 'amazon_s3.yml')
    unless(s3_present)
      s3_fields = ""
    else
      redactor_s3 = RedactorS3Helper.new
      policy = redactor_s3.policy_document
      sign = redactor_s3.upload_signature
      success_action_redirect = "#{Fedena.hostname}/redactor/post_upload"

      s3_fields = "<input id='signature' type='hidden' name='signature' value='#{sign}'>" +
        "<input id='acl' type='hidden' name='acl' value='public-read'>" +
        "<input id='key' type='hidden' name='key' value='temp/#{(Time.now + (60*1000)).to_time.to_i}/${filename}'>" +
        "<input id='AWSAccessKeyId' type='hidden' name='AWSAccessKeyId' value='#{Config.access_key_id}'>" +
        "<input id='policy' type='hidden' name='policy' value='#{policy}'>" +
        "<input id='success_action_redirect' type='hidden' name='success_action_redirect' value='#{success_action_redirect}'>"
    end

    if options[:ajax]
      inputs = "<input type='hidden' id='#{id}_hidden' name='#{object_name}[#{field}]'>\n"
    else
      inputs = s3_fields +
        ActionView::Helpers::InstanceTag.new(object_name, field, self, options.delete(:object)).to_text_area_tag(options.merge({:id=>id,:style=>"background: transparent !important;border: 2px solid #ddd !important;",:class=>"redactor_call redactor_call_style"})) +
        "<input id='redactor_to_update' name='#{object_name}[redactor_to_update]' type='hidden' value=''>" +
        "<input id='redactor_to_delete' name='#{object_name}[redactor_to_delete]' type='hidden' value=''>"
    end

  end
  def redactor_element_id(object_name, field)
    "#{object_name.to_s.gsub('][','_').gsub('[','_').gsub(']','')}_#{field}"
  end

  def load_latex_preview

    content_for :redactor do
      "<script type='text/x-mathjax-config'>MathJax.Hub.Config({tex2jax: {inlineMath: [['~~','~~'], ['\\(','\\)']]}});</script>
         <script type='text/javascript'  src='http://latex.uzity.com/MathJax/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>"
    end

  end

  def ping(url)
    regex = /^.*(http|https):\/\/(.*).*$/
    m = url.match(regex)
    url = $2 || url
    domain = url.split('/').first
    url_resource = url.split(domain).last
    begin
      if(url_resource.present?)
        return Net::HTTP.new("#{domain}").head(url_resource).kind_of? Net::HTTPOK
      else
        return Net::HTTP.new("#{domain}").head('/').kind_of? Net::HTTPOK
      end
    rescue
      return false
    end
  end

  def load_redactor_script
    s3_present = File.exist? File.join(::Rails.root, 'config', 'amazon_s3.yml')
    unless(s3_present)
      image_upload_options = "imageUpload: '/redactor/upload',
                                                uploadFields: {'authenticity_token':j('input[name=authenticity_token]').val()},"
      s3_fields = ""
      #        latex_plugin = ""
      #        latex_html = ""
    else
      redactor_s3 = RedactorS3Helper.new
      policy = redactor_s3.policy_document
      sign = redactor_s3.upload_signature
      success_action_redirect = "#{Fedena.hostname}/redactor/post_upload"
      image_upload_options = "imageUpload: 'https://#{Config.bucket_public}.s3.amazonaws.com/',
              uploadCrossDomain: true,
              uploadFields: {
                'key': '#key',
                'AWSAccessKeyId': '#AWSAccessKeyId',
                'acl': '#acl',
                'success_action_redirect': '#success_action_redirect',
                'policy': '#policy',
                'signature': '#signature'
              } ,"
      s3_fields = "<input id='signature' type='hidden' name='signature' value='#{sign}'>" +
        "<input id='acl' type='hidden' name='acl' value='public-read'>" +
        "<input id='key' type='hidden' name='key' value='temp/#{(Time.now + (60*1000)).to_time.to_i}/${filename}'>" +
        "<input id='AWSAccessKeyId' type='hidden' name='AWSAccessKeyId' value='#{Config.access_key_id}'>" +
        "<input id='policy' type='hidden' name='policy' value='#{policy}'>" +
        "<input id='success_action_redirect' type='hidden' name='success_action_redirect' value='#{success_action_redirect}'>"
    end

    if(@latex && ping(FEDENA_SETTINGS[:mathjaxurl]))
      latex_plugin ="advanced"
      latex_js = "<script src='/javascripts/redactor/advanced.js' type='text/javascript'></script>"
      latex_html = "<div id='latex' style='display:none'>\
                              <div class='latex-editor'>\
                                <section>\
                                  <p>\
                                    Enter tex expression\
                                    <button class='latexp-preview-btn redactor_modal_btn'>Preview</button>\
                                  </p>\
                                </section>\
                                <textarea class='latex-expression' id='MathInput' name='latex-expression' rows='3' cols='64' type='text'></textarea>\
                                <br>\
                                <div class='tex2jax_process latex-preview-output'>\
                              </div>\
                              <footer padding: 0px 15px 10px;>\
                                <div class='footer-btns'>\
                                  <a href='#' class='redactor_modal_btn redactor_btn_modal_close'>Cancel</a>\
                                  <button id='latexp-link' class='redactor_modal_btn redactor_latex_insert_btn'>Insert</button>\
                                </div>\
                              </footer>\
                             </div>\
                            </div>"
      latex_js_include = "<script type='text/javascript' src='#{FEDENA_SETTINGS[:mathjaxurl]}'></script>"
    else
      latex_plugin = ""
      latex_js = ""
      latex_html = ""
    end

    direction = rtl? ? 'rtl':'ltr'
    content_for :head do
      stylesheet_link_tag "redactor/redactor","redactor/style"
    end

    if File.exist? File.join(::Rails.root,"/public/javascripts/redactor/langs/#{I18n.locale}.js")
      lang_js = "#{I18n.locale}"
    else
      lang_js = "en"
    end

    content_for :redactor do
      "<script src='/javascripts/redactor/fontcolor.js' type='text/javascript'></script>
       #{latex_js}
       <script src='/javascripts/redactor/redactor.js' type='text/javascript'></script>
       #{latex_js_include}
      <script src='/javascripts/redactor/langs/#{lang_js}.js' type='text/javascript'></script>
        <script>
          window.onload = function(){
            j('.redactor_call').each(function(a,b){
            console.log('id:'+b.id);
            j('.redactor_call').redactor({
                buttons: ['html', '|',
                          'bold', 'italic', 'underline','deleted','|',
                          'redo', 'undo', '|',
                          'selectall', '|',
                          'formatting', '|',
                          'subscript','superscript', '|',
                          'unorderedlist', 'orderedlist', 'outdent', 'indent', '|',
                          'alignment', '|',
                          'horizontalrule', '|',
                          'image', 'video', 'file', 'table', 'link'],
                buttonsCustom: {
                          superscript: {
                              title: 'Superscript',
                              callback: function(event, key) {
                                  this.execCommand(event,'superscript');
                              }
                          },
                          subscript: {
                              title: 'Subscript',
                              callback: function(obj, event, key) {
                                  this.execCommand('subscript');
                              }
                          },
                          redo: {
                              title: 'Redo',
                              callback: function(event, key) {
                                  this.execCommand(event,'redo');
                              }
                          },
                          undo: {
                              title: 'Undo',
                              callback: function(obj, event, key) {
                                  this.execCommand('undo');
                              }
                          },
                          selectall: {
                              title: 'Select all',
                              callback: function(obj, event, key) {
                                  this.selectall = true;
                                  this.execCommand('selectall');
                              }
                          },
                          paste: {
                              title: 'Paste',
                              callback: function(obj, event, key) {
                                  //this.selectall = true;
                                  console.log(event);
                                  console.log(obj);
                                  this.execCommand('inserthtml');
                              }
                          }
                        },
                focus: true,
                plugins: ['fontcolor','#{latex_plugin}'],
                direction: '#{direction}',
                lang: '#{I18n.locale}',
                #{image_upload_options}
                imageUploadErrorCallback: function(json){
                  j('#redactor_upload_errors_'+b.id).attr('style','display:block');
                  j('#redactor_upload_errors_'+b.id).html(json.error_message);
                },
                imageDeleteCallback: function(image){
                  image_location = image[0].src;
                  console.log('src: '+image_location);
                  reg = /^.*uploads([0-9\\/]*)\\/images.*$/;
                  old_ids_to_delete = j('#redactor_to_delete').val();
                  old_ids_to_update = j('#redactor_to_update').val();
                  console.log('rmatch: ' + reg.match(image_location));
                  if(reg.match(image_location)){
                    image_location.match(reg);
                    new_id_to_delete = parseInt(RegExp.$1.split('/').join(''));
                    if(old_ids_to_delete == ''){
                      new_ids_to_delete = [ new_id_to_delete ];
                    }else{
                      new_ids_to_delete = old_ids_to_delete.split(',');
                      new_ids_to_delete.push(new_id_to_delete);
                      new_ids_to_delete = new_ids_to_delete.join(',');
                    }
                    if(old_ids_to_update != ''){
                      added_ids = old_ids_to_update.split(',');
                      if(added_ids.include(new_id_to_delete)){
                        added_ids.splice(added_ids.indexOf(new_id_to_delete.toString()),1);
                      }
                    }
                    j('#redactor_to_delete').val(new_ids_to_delete);
                    j('#redactor_to_update').val(added_ids.join(','));
                  }
                },
                imageUploadCallback: function(image, json){
                  console.log(json);
                  console.log(image);
                  new_id_to_update = json.id;
                  console.log(json.id);
                  old_ids_to_update = j('#redactor_to_update').val();
                  if(old_ids_to_update == ''){
                    new_ids_to_update = [ new_id_to_update ]
                  }else{
                    new_ids_to_update = old_ids_to_update.split(',');
                    new_ids_to_update.push(new_id_to_update);
                    new_ids_to_update = new_ids_to_update.join(',');
                  }
                  j('#redactor_to_update').val(new_ids_to_update);
                }
              });

              j('#'+b.id).parent().prepend('<div class=\"redactor_upload_errors\" id=\"redactor_upload_errors_'+b.id+'\"></div>');

              j('.redactor_editor').find('iframe').each(function(a,b){
                if(b.src.indexOf('youtube.com')>=0 && b.src.indexOf('wmode')==-1){
                  b.src = b.src+'?wmode=opaque';
                }
              });
              j('.redactor_box').on('click',function(){
                console.log('clicked');
                if(j('#redactor_upload_errors_'+b.id).html().length != 0){
                  j('#redactor_upload_errors_'+b.id).attr('style','');
                  j('#redactor_upload_errors_'+b.id).html('');
                }
              })
          })
            j('#page-yield').append(\"#{latex_html}\");
            j('.redactor_box').find('textarea').removeClass('redactor_call_style');
          }
        </script>"
    end
  end
end
module ActionView
  module Helpers
    class FormBuilder
      def redactor(method, options = {})
        @template.redactor(@object_name, method, options.merge(:object => @object))
      end
    end
  end
end