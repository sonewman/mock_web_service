require 'sinatra/base'
require 'rack'
require 'mock_web_service/application'
require 'mock_web_service/request'
require 'mock_web_service/server'
require 'stringio'
require 'forwardable'

module MockWebService
  class Handler < Rack::Handler::WEBrick
    extend Forwardable

    HTTP_HOST       = 'HTTP_HOST'.freeze
    HTTP_VERSION    = 'HTTP_VERSION'.freeze
    HTTPS           = 'HTTPS'.freeze
    PATH_INFO       = 'PATH_INFO'.freeze
    REQUEST_METHOD  = 'REQUEST_METHOD'.freeze
    REQUEST_PATH    = 'REQUEST_PATH'.freeze
    SCRIPT_NAME     = 'SCRIPT_NAME'.freeze
    QUERY_STRING    = 'QUERY_STRING'.freeze
    SERVER_PROTOCOL = 'SERVER_PROTOCOL'.freeze
    SERVER_NAME     = 'SERVER_NAME'.freeze
    SERVER_ADDR     = 'SERVER_ADDR'.freeze
    SERVER_PORT     = 'SERVER_PORT'.freeze
    CACHE_CONTROL   = 'Cache-Control'.freeze
    CONTENT_LENGTH  = 'Content-Length'.freeze
    CONTENT_TYPE    = 'Content-Type'.freeze

    GET     = 'GET'.freeze
    POST    = 'POST'.freeze
    PUT     = 'PUT'.freeze
    PATCH   = 'PATCH'.freeze
    DELETE  = 'DELETE'.freeze
    HEAD    = 'HEAD'.freeze
    OPTIONS = 'OPTIONS'.freeze
    LINK    = 'LINK'.freeze
    UNLINK  = 'UNLINK'.freeze
    TRACE   = 'TRACE'.freeze

    attr_accessor :endpoints, :method, :matched_handler
    def_delegator :@server, :start, :start
    def_delegator :@server, :stop, :stop

    def initialize endpoints
      @endpoints = endpoints
    end

    ##
    # in order to trick the http_router
    # into thinking this is actually handled by rack
    # we need to make the request look like it would
    # from Rack::Handler::WEBrick
    def create_env req, res
      res.rack = true
      env = req.meta_vars
      env.delete_if { |k, v| v.nil? }

      rack_input = StringIO.new(req.body.to_s)
      rack_input.set_encoding(Encoding::BINARY) if rack_input.respond_to?(:set_encoding)

      env[HTTP_VERSION] ||= env[SERVER_PROTOCOL]
      env[QUERY_STRING] ||= ""
      unless env[PATH_INFO] == ""
        path, n = req.request_uri.path, env[SCRIPT_NAME].length
        env[PATH_INFO] = path[n, path.length-n]
      end
      env[REQUEST_PATH] ||= [env[SCRIPT_NAME], env[PATH_INFO]].join

      # return env
      env
    end

    def handle req, res
      dup.handle! req, res
    end

    def handle! req, res
      env = create_env req, res

      @method = env[REQUEST_METHOD].downcase.to_sym
      @matched_handler = @endpoints.get_endpoint @method, env

      if @matched_handler
        @app = self
        return service req, res
      end
    end

    def call env
      app = App.new self
      app.call env
    end

    def do_handling req
      @endpoints.do_handling @matched_handler, @method, req
    end
  end

  class App < Sinatra::Base

    def initialize handler
      @handler = handler
      super
    end

    def route!(base = settings, pass_block = nil)
      req = Request.new @request

      # set a local reference so we can get
      # to it inside of `dispatch!`
      @current_request = req

      # get relevent handle for this requesta
      @handler.do_handling req
    end

    def dispatch!
      # catch the normal response
      # so we can return it correctly
      super

      if Array === body and body[0].respond_to? :content_type
        content_type body[0].content_type
      else
        content_type :html
      end

      # set body, headers & status for access in
      @current_request.set_response @response

      # return normal response
      nil
    end
  end
end
