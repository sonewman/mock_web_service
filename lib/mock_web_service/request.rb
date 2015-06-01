module MockWebService
  class Request
    attr_reader :headers, :body, :query_string, :method, :path, :endpoint
    attr_accessor :response, :params

    alias :query :query_string

    REQUEST_VARS = [:path, :session, :host, :port, :content_length, :content_type,
    :host_with_port, :content_charset, :referrer, :referer, :user_agent, :base_url,
    :url, :fullpath, :accept_encoding, :accept_language, :cookies]

    def initialize req, res, endpoint, params
      @method = req.request_method
      @body = req.body.read
      @headers = req.env.select {|key, value| key.upcase == key}
      @query_string = Request::parse req.env['QUERY_STRING']
      @params = params
      @endpoint = endpoint

      @response = res

      REQUEST_VARS.each do |name|
        instance_variable_set("@#{name}", req.send(name))
      end

    end

    REQUEST_VARS.each do |name|
      define_method name.to_s do
        instance_variable_get "@#{name}"
      end
    end

    HEADER_PARAM = /\s*[\w.]+=(?:[\w.]+|"(?:[^"\\]|\\.)*")?\s*/

    def self.parse uri
      params = uri.scan(HEADER_PARAM).map! do |s|
        key, value = s.strip.split('=', 2)
        value = value[1..-2].gsub(/\\(.)/, '\1') if value.start_with?('"')
        [key, value]
      end

      Hash[params]
    end
  end
end
