
module MockWebService
  class Handle
    attr_reader :history, :is_default
    attr_accessor :callback

    def initialize query, &callback
      @history = []
      @query = query

      if callback
        @callback = callback
        @is_default = false
      else
        @callback = lambda{|req| [404]}
        @is_default = true
      end
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
