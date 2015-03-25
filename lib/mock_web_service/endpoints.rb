module MockWebService
  class Endpoints
    class << self; attr_accessor :methods end
    @methods = :get, :put, :post, :delete, :head, :options

    def initialize
      @handles = {}
      reset
    end

    def handle method, path, handle=lambda{[500]}
      @handles[method][path] ||= {
        handle: handle,
        history: []
      }
    end

    def on_request method, path, request, env
      endpoint = handle method, path
      parsed_request = parse_request(request, env)
      endpoint[:history] << parsed_request
      endpoint[:handle].call parsed_request
    end

    def log method, path
      handle(method, path)[:history]
    end

    def reset
      Endpoints.methods.each do |method|
        @handles[method] = {}
      end
    end

    private
      def parse_request request, env
        return nil unless request
        headers = env.select { |key, value| key.upcase == key }
        MockWebService::Request.new headers, request.body.read
      end
  end

  class Request
    attr_accessor :headers
    attr_accessor :body
    def initialize(headers, body)
      @headers = headers
      @body = body
    end
  end
end
