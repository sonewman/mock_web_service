require 'mock_web_service'
require 'sinatra/base'
require 'rack'
include MockWebService

def start_api host, port
  Thread.abort_on_exception = true

  server = nil
  started = false
  server_thread = Thread.new do
    app = Proc.new { [200, {}, ['OK!!!']] }
    server = Rack::Server.new(app: app, Host: host, Port: port)
    started = true
    server.start
  end

  stop = Proc.new {
    if server_thread
      server_thread.kill
      server_thread.join
      server_thread = nil
    end
  }

  until ::Time.now > ::Time.now + 10
    sleep 0.25
    return stop if started
  end
  stop.call
  raise 'Timed out waiting for service to start'
end

host_name = '0.0.0.0'
port = 1925

url = "http://#{host_name}:#{port}"

describe MockWebService do
  before :each do
    mock.start host_name, port
    @stop_api = start_api '0.0.0.0', '1926'
  end

  after :each do
    mock.stop
    @stop_api.call
  end

  it 'should proxy get request' do
    mock.default_proxy :get, 'http://0.0.0.0:1926/'

    # make HTTP request to API
    response = HTTParty.get "#{url}/route/working"

    # assert response code 200
    expect(response.code).to be 200

    # assert response body is equal to expected
    expect(response.body).to eql 'OK!!!'
  end
end
