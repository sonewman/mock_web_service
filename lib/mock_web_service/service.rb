require 'forwardable'
require 'webrick'
require 'rack'
require 'mock_web_service/application'

module MockWebService
  class Service
    extend Forwardable

    attr_accessor :started
    def_delegator :@endpoints, :reset, :reset
    def_delegator :@endpoints, :log, :log

    def initialize
      @started = false
      @endpoints ||= Endpoints.new
    end

    def start host, port
      @host = host
      @port = port
      return if @started

      Thread.abort_on_exception = true
      @app = App.new @endpoints

      @server_thread = Thread.new do
        Rack::Handler::WEBrick.run(@app, Host: @host, Port: @port) {|server|
          @server = server
        }
      end

      @started = true

      # default timeout is 10ms
      wait_for_server 10
    end

    def stop
      @started = false

      # shutdown server and close port
      if @server
        @server.shutdown
        @server = nil
      end

      # kill server thread
      if @server_thread
        # add join to delay after killing the thread
        # this prevents edge case race conditions
        # between stopping and starting on the same thread
        @server_thread.join
        @server_thread.kill
        @server_thread = nil
      end
    end

    # create methods for request verbs:
    # get, put, post, delete, head, options
    Endpoints.methods.each do |method|
      define_method method.to_s do |path, &cb|
        puts "Adding endpoint: #{method.upcase} #{path}"
        # get handle for the method and path
        @endpoints.set_handle method, path, &cb
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
