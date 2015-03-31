require 'sinatra/base'
require 'mock_web_service/request'

module MockWebService
  class App < Sinatra::Base

    def initialize endpoints
      @endpoints = endpoints
      @current_handle = nil
      super
    end

    Endpoints.methods.each do |method|
      send method.to_s, '*' do
        req = Request.new request

        # get relevent handle for this request
        handle = @endpoints.on_request method, req

        # create circular reference
        # to allow access to more info when mocking
        req.endpoint = handle

        handle.history << req

        # set a local reference so we can get
        # to it inside of `dispatch!`
        @current_request = req
        
        handle.callback.call req
      end
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
