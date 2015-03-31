
module MockWebService
  class Handle
    attr_reader :history
    attr_accessor :callback

    def initialize query, &callback
      @history = []
      @query = query
      @callback = callback ||= lambda{|req|
        [500]
      }
    end

    def match? q
      return true if @query == q || @query.empty?

      matched = true
      @query.each do |k, v|
        if v != q[k]
          matched = false
          break
        end
      end

      matched
    end
  end
end
