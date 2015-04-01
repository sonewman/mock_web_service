require 'mock_web_service/handle'

module MockWebService
  class Endpoint
    def initialize
      @queries = []
    end

    def each_query &cb
      @queries.each &cb
    end

    def find_query query
      error = nil
      match = nil
      each_query do |q|
        if q.match? query
          unless q.is_default
            match = q
            break
          else
            error = q
          end
        end
      end
      match || error
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
