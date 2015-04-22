require 'uri'
require 'mock_web_service/request'
require 'http_router'

module MockWebService
  class Endpoints

    class << self; attr_accessor :methods end
    @methods = :get, :put, :post, :delete, :head, :options

    def initialize
      @methods = {}
      @history = {}
      @not_found = lambda{|req| [404]}

      Endpoints.methods.each {|method|
        @methods[method] = HttpRouter.new
        @history[method] = {}
      }
    end

    def get_endpoint method, env
      endpoints = @methods[method] 

      if endpoints
        endpoint = endpoints.recognize env
        if endpoint.first && endpoint.first.length > 0
          match = endpoint.first.first
          route = match.route
          return [route.dest.call, match.params]
        end
      end
      
      [@not_found, {}]
    end

    def set_handle method, path, &cb
      @methods[method].add(path).to{cb}
    end

    def on_request method, rack_request, req
      handle = get_endpoint method, rack_request.env
      req.endpoint = handle.first
      req.params = handle.last
      log(method, req.path) << req
      req.endpoint.call req
    end

    def reset
      Endpoints.methods.each {|method|
        @methods[method].reset!
      }
    end

    def log method, path
      @history[method][path] ||= []
    end

  end
end
