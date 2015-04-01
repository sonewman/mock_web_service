require 'sinatra/base'

REQUEST_VARS= [:path, :session, :host, :port, :content_length, :content_type,
  :host_with_port, :content_charset, :referrer, :referer, :user_agent, :base_url,
  :url, :fullpath, :accept_encoding, :accept_language, :params, :cookies]

module MockWebService

  class Response
    attr_reader :body, :status, :code, :headers, :length

    def initialize res
      # join the whole response body
      @body = res.body.join ''

      # set headers to duplicate of the responses
      @headers = res.headers.dup

      # add aliases for status code
      @status = res.status
      @code = @status

      # set content-length
      @length = @body.bytesize
      @headers['content_length'] = @length
    end
  end

  # This class (MockWebService::Request) wraps
  # Sinatra::Request [< Rack::Request]
  # It provides some accessors to retrieve
  # certain generic
  class Request
    attr_reader :headers, :body, :query, :method, :path
    attr_accessor :endpoint, :response

    def initialize req
      @method = req.request_method
      @body = req.body.read
      @headers = req.env.select {|key, value| key.upcase == key}
      @query = req.params

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

    def set_response res
      @response = Response.new(res) unless @response
    end
  end
end
