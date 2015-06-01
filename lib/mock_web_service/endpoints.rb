require 'uri'
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

      @not_found = Proc.new {|env|
        cb = Proc.new {|req| [404]}
        Handle::call(env, {}, cb)
      }

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

    def set_handle method, path, &cb
      @methods[method].add(path).to {|params|
        Proc.new {|env| Handle::call(env, params, cb) }
      }
    end

    def default_set_proxy method = nil, url
      proxy = Proxy.new url
      proxyHandle = Proc.new {|env|
        Handle::call env, {}, proxy
      }

      if method
        @default_proxies[method] = proxyHandle
      else
        Endpoints.methods.each {|verb|
          @default_proxies[verb] = proxyHandle
        }
      end
    end

    def default_unset_proxy method
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

    def log method, path
      @history[method][path] ||= []
    end
  end
end
