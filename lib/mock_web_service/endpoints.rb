require 'uri'
require 'mock_web_service/endpoint'
require 'mock_web_service/handle'
require 'mock_web_service/request'

module MockWebService
  class Endpoints

    class << self; attr_accessor :methods end
    @methods = :get, :put, :post, :delete, :head, :options

    def initialize
      @routes = {}
      Endpoints.methods.each {|method|
        @routes[method] = {}
      }
    end

    def get_endpoint method, path
      # get the endpoint for the supplied
      # path on the given method
      endpoint = @routes[method][path]

      # if we don't have an endpoint then
      # we need to make a new one
      unless endpoint
        endpoint = Endpoint.new
        @routes[method][path] = endpoint
      end

      endpoint
    end

    def get_handle method, path, &cb
      # parse the path to separate relevant parts
      uri = URI path

      # override parsed path
      path = uri.path

      # parse query string if there is one
      query = uri.query ? Request::parse(uri.query) : {}

      cb.call query, get_endpoint(method, path)
    end

    def set_handle method, path, &cb
      get_handle method, path do |query, endpoint|
        # set callback handle for the given query
        endpoint.set_query query, &cb
      end
    end

    def on_request method, req
      endpoint = get_endpoint method, req.path
      endpoint.get_query req.params
    end

    def reset
      Endpoints.methods.each {|method|
        @routes[method].clear
      }
    end

    def log method, path
      history = []

      get_handle method, path do |query, endpoint|
        endpoint.each_query do |q|
          if q.match? query
            history.concat q.history
          end
        end
      end

      history
    end
  end
end
