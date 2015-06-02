require 'forwardable'
require 'webrick'
require 'rack'
require 'mock_web_service/handle'
require 'mock_web_service/server'

module MockWebService
  class Service
    extend Forwardable

    attr_accessor :started
    def_delegator :@endpoints, :log, :log
    def_delegator :@endpoints, :reset, :reset
    def_delegator :@endpoints, :reset_all, :reset_all
    def_delegator :@endpoints, :reset_default_proxy, :reset_default_proxy

    def initialize
      @started = false
      @endpoints ||= Endpoints.new
    end

    def start host, port
      return if @stop_api
      @host = host
      @port = port

      config = { Host: @host, Port: @port }
      app = Proc.new {|env|
        @endpoints.resolve env
      }

      @stop_api = Server::start(config, app)
    end

    def stop
      @stop_api.call if @stop_api
      @stop_api = nil
    end

    def set_proxy method=nil, path=nil, proxy_url
      if method.is_a? String
        path = method
        method = nil
      end

      if path
        @endpoints.set_proxy method, path, proxy_url
      else
        default_proxy(method, proxy_url)
      end
    end

    def unset_proxy method=nil, path=nil, proxy_url
      if method.is_a? String
        path = method
        method = nil
      end

      if path
        @endpoints.reset_proxy method, path, proxy_url
      else
        reset_default_proxy(method, proxy_url)
      end
    end

    def default_proxy method=nil, proxy_url
      @endpoints.default_set_proxy method, proxy_url
    end

    def reset_default_proxy method=nil
      @endpoints.default_unset_proxy method
    end

    # create methods for request verbs:
    # get, put, post, delete, head, options
    Endpoints.methods.each do |method|
      define_method method.to_s do |path, &cb|
        puts "Adding endpoint: #{method.upcase} #{path}"
        # get handle for the method and path
        @endpoints.set_handle method, path, cb
      end
    end

    private
      def wait_for_server timeout
        until ::Time.now > ::Time.now + timeout
          sleep 0.25
          return if @started
        end
        raise 'Timed out waiting for service to start'
      end
  end
end
