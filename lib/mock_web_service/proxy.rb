require 'uri'

module MockWebService
  class Proxy
    def initialize uri
      @uri = uri.is_a?(String) ? URI(uri) : uri
    end

    def resolve_path path
      path = path[1..-1] if @uri.path[0] == '/'
      @uri.path + path
    end

    def call req
      res = nil
      options = { :use_ssl => @uri.scheme == 'https' }
      Net::HTTP.start(@uri.host, @uri.port, options) do |http|
        r = make_request http, req.method, req.path, req.headers, req.body
        res = [r.code.to_i, r.to_hash, [r.body]]
      end
      res
    end

    private
      def req method, req_body, res_body, path, headers
        Net::HTTPGenericRequest.new(method, req_body, res_body, path, headers)
      end

      def make_request http, method, path, headers, body
        has_req_body = body ? true : false
        has_res_body = method != 'HEAD'
        headers = parse_headers headers
        path = resolve_path path
        http.request(req(method, has_req_body, has_res_body, path, headers), body)
      end

      def parse_headers headers
        headers.select {|k,v| k.start_with? 'HTTP_'}
          .reduce({}) {|h, pair|
            key = pair[0]
              .sub(/^HTTP_/, '')
              .downcase
              .gsub(/(^([\w])|\_([\w]))/) {|m|
                m[0] == '_' ? '-' + m[1..-1].upcase : m.upcase
              }
            h[key] = pair[1]
            h
          }
      end
  end
end
