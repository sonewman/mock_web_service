require 'mock_web_service/request'
require 'mock_web_service/response'
require 'net/http'
require 'rack'

module MockWebService
  class Handle
    def self.call env=nil, params={}, cb=nil
      res = Response.new
      req = Request.new(Rack::Request.new(env), res, cb, params)
      response = res.finish(cb.call(req))
      [req, response]
    end
  end
end
