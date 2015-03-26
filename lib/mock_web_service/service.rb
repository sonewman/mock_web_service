require 'forwardable'
require 'webrick'
require 'rack'
require 'sinatra/base'

module MockWebService
  class App < Sinatra::Base
    def initialize endpoints
      @endpoints = endpoints
      super
    end

    Endpoints.methods.each do |method|
      send method.to_s, '*' do |path|
        @endpoints.on_request method, path, request, env
      end
    end
  end

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
        @server_thread.kill
        @server_thread = nil
      end
    end

    # create methods for request verbs:
    # get, put, post, delete, head, options
    Endpoints.methods.each do |method|
      define_method method.to_s do |path, &handle|
        @endpoints.handle method, path, handle
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
