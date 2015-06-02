require 'mock_web_service/request'
require 'http_router'
require 'rack'
require 'mock_web_service/handle'
require 'mock_web_service/proxy'

module MockWebService
  class Endpoints

    class << self; attr_accessor :methods end
    @methods = :get, :put, :post, :delete, :head, :options
    attr_accessor :endpoints, :method, :matched_handler

    def initialize
      @methods = {}
      @history = {}
      @default_proxies = {}

      cb = Proc.new {|req| [404]}
      @not_found = createHandle({}, cb)

      Endpoints.methods.each {|method|
        @methods[method] = HttpRouter.new
        @history[method] = {}
      }
    end

    def resolve env
      method = env['REQUEST_METHOD'].downcase.to_sym
      endpoint = nil

      endpoints = @methods[method]

      if endpoints
        matched = endpoints.recognize env

        if matched.first and matched.first.length > 0
          match = matched.first.last
          route = match.route

          endpoint = route.dest.call(match.params)
        end
      end

      unless endpoint
        endpoint = @default_proxies[method] || @not_found
      end

      req, handle_response = endpoint.call env
      log(method, req.path) << req
      handle_response
    end

    def createHandle params, cb
      Proc.new {|env| Handle::call(env, params, cb) }
    end

    def set_handle method, path, cb
      @methods[method].add(path).to {|params| createHandle(params, cb) }
    end

    def set_proxy method, path, url
      if method
        set_handle(method, path, Proxy.new(url))
      else
        Endpoints.methods.each {|verb|
          set_handle(verb, path, Proxy.new(url))
        }
      end
    end

    def default_set_proxy method=nil, url
      proxyHandle = createHandle({}, Proxy.new(url))

      if method
        @default_proxies[method] = proxyHandle
      else
        Endpoints.methods.each {|verb|
          @default_proxies[verb] = proxyHandle
        }
      end
    end

    def reset_default_proxy method
      if method
        @default_proxies[method] = nil
      else
        Endpoints.methods.each {|verb|
          @default_proxies[verb] = nil
        }
      end
    end

    def reset
      Endpoints.methods.each {|method|
        @methods[method].reset!
      }
    end

    def reset_all
      reset_default_proxy
      reset
    end

    def log method, path
      @history[method][path] ||= []
    end
  end
end
