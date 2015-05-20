require 'webrick/httpproxy'

module MockWebService
  class Server < WEBrick::HTTPProxyServer

    def initialize handler, options
      @handler = handler
      environment  = ENV['RACK_ENV'] || 'development'
      default_host = environment == 'development' ? 'localhost' : '0.0.0.0'
      options[:BindAddress] = options.delete(:Host) || default_host
      options[:Port] ||= 8080
      super options
    end

    def service req, res
      response = @handler.handle req, res
      return response if response


    end
  end
end
