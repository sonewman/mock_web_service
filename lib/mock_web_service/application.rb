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
        mock_req = Request.new request

        # set a local reference so we can get
        # to it inside of `dispatch!`
        @current_request = mock_req

        # get relevent handle for this request
        @endpoints.on_request method, request, mock_req
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
