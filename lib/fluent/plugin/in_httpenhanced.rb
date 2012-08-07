module Fluent
  class HttpEnhanced < Fluent::HttpInput
    Plugin.register_input('httpenhanced', self)

    config_param :full_query_string_record, :bool, :default => 'false'
    config_param :respond_with_empty_img, :bool, :default => 'false'
    config_param :default_tag, :default => ''

    def on_request(path_info, params)
      if @full_query_string_record == true
        begin
          path = path_info[1..-1] # remove /
          tag = path.split('/').join('.')
          return ["200 OK", {'Content-type'=>'text/xml'}, CROSSDOMAIN_XML]unless tag.downcase.match("crossdomain.xml").nil?

          tag = @default_tag if tag == '' && @default_tag != ''
          record = params
          time = params['time']
          time ||= params['t']
          time = time[0..9].to_i  # just make sure that its 10 digits epoch time in seconds not miliseconds
          if time == 0
            time = Engine.now
          end
        rescue
          return ["400 Bad Request", {'Content-type'=>'text/plain'}, "400 Bad Request\n#{$!}\n"]
        end
        begin
          Engine.emit(tag, time, record)
        rescue
          return ["500 Internal Server Error", {'Content-type'=>'text/plain'}, "500 Internal Server Error\n#{$!}\n"]
        end

        if @respond_with_empty_img == true
          return ["200 OK", {'Content-type'=>'image/gif'}, "GIF89a\u0001\u0000\u0001\u0000\x80\xFF\u0000\xFF\xFF\xFF\u0000\u0000\u0000,\u0000\u0000\u0000\u0000\u0001\u0000\u0001\u0000\u0000\u0002\u0002D\u0001\u0000;"]
        else
          return ["200 OK", {'Content-type'=>'text/plain'}, ""]
        end
      else
        super(path_info, params)
      end
    end
    CROSSDOMAIN_XML=<<EOF
<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
    <allow-access-from domain="*" />
</cross-domain-policy>
EOF
  end
end
