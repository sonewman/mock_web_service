require 'rack'

module MockWebService
  class Server
    def self.start options, app
      Thread.abort_on_exception = true

      server = nil
      started = false

      server_thread = Thread.new do
        Rack::Handler::WEBrick.run(app, options) {|s|
          server = s
          started = true
        }
      end

      stop = Proc.new {
        if server
          server.shutdown
          server = nil
        end

        if server_thread
          server_thread.kill
          server_thread.join
          server_thread = nil
        end
        sleep 0.1
      }

      until ::Time.now > ::Time.now + 10
        sleep 0.25
        return stop if started
      end

      stop.call
      raise 'Timed out waiting for service to start'
    end
  end
end
