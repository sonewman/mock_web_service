require 'rack'

module MockWebService
  class Response
    attr_reader :body, :status, :code, :headers, :length

    def finish res
      return @response if @response

      status, headers, body = handle_response res
      response = Rack::Response.new body, status, headers

      # join the whole response body
      @body = body.join ''

      # set headers to duplicate of the responses
      @headers = headers

      # add aliases for status code
      @status = status
      @code = @status

      # set content-length
      @length = @body.bytesize
      @headers['content_length'] = @length

      response.finish
    end
  end

  def handle_response res
    return [200, {}, []] unless res
    return [200, {}, [res]] if res.kind_of? String

    if res.kind_of? Array
      ##
      # since this `was` following sinatra's
      # API the response Array is likely to be
      # in the wrong order for rack
      #
      # It therefore expects it to contain:
      #
      # [*Status*, *Headers*, *Body*]
      #
      status, headers, body = res

      unless body
        if status.is_a? String or status.is_a? Array
          body = status
          status = 200
        end
      end

      unless body
        if headers.is_a? String or status.is_a? Array
          body = headers
          headers = Hash.new
        end
      end

      if body
        body = [body] unless body.is_a? Array
      else
        body = []
      end

      status = 200 unless status.is_a? Numeric
      headers = Hash.new unless headers.is_a? Hash
    end

    [status, headers, body]
  end
end
