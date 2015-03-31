require 'mock_web_service/handle'

module MockWebService
  class Endpoint
    def initialize
      @queries = []
      @default = Handle.new Hash.new
    end

    def each_query &cb
      @queries.each &cb
    end

    def find_query query
      match = nil
      each_query do |q|
        if q.match? query
          match = q
          break
        end
      end
      match
    end

    def get_query query
      matched = find_query query

      unless matched
        matched = Handle.new query
        @queries << matched
      end

      matched
    end

    def set_query query, &cb
      handle = get_query query
      handle.callback = cb
    end
  end
end
