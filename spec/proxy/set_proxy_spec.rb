require 'mock_web_service'
include MockWebService

host_name = '0.0.0.0'
port = 1925

url = "http://#{host_name}:#{port}"

describe MockWebService do
  before :each do
    mock.start host_name, port
    @options = { Host: '0.0.0.0', Port: '1926' }
  end

  after :each do
    mock.stop
  end

  it 'should default proxy `get` request' do
    stop_api = MockWebService::Server.start(@options, Proc.new(){[200, {}, ['OK!!!']]})

    mock.set_proxy :get, '/abc', 'http://0.0.0.0:1926/'

    # make HTTP request to API
    response = HTTParty.get "#{url}/abc"

    # assert response code 200
    expect(response.code).to be 200

    # assert response body is equal to expected
    expect(response.body).to eql 'OK!!!'

    stop_api.call
  end

  it 'should default proxy `post` request' do
    stop_api = MockWebService::Server.start(@options, Proc.new(){|env|
      req = Rack::Request.new env

      expect(req.request_method).to eql 'POST'
      expect(req.body.read).to eql 'ABC'

      [200, {}, ['OK!!!']]
    })

    mock.set_proxy :post, '/abc', 'http://0.0.0.0:1926/'

    # make HTTP request to API
    response = HTTParty.post "#{url}/abc", { body: 'ABC' }

    # assert response code 200
    expect(response.code).to be 200

    # assert response body is equal to expected
    expect(response.body).to eql 'OK!!!'

    stop_api.call
  end
  
  it 'should default proxy `put` request' do
    stop_api = MockWebService::Server.start(@options, Proc.new(){|env|
      req = Rack::Request.new env

      expect(req.request_method).to eql 'PUT'
      expect(req.body.read).to eql 'ABC'

      [200, {}, ['OK!!!']]
    })

    mock.set_proxy :put, '/abc', 'http://0.0.0.0:1926/'

    # make HTTP request to API
    response = HTTParty.put "#{url}/abc", { body: 'ABC' }

    # assert response code 200
    expect(response.code).to be 200

    # assert response body is equal to expected
    expect(response.body).to eql 'OK!!!'

    stop_api.call
  end
  
  it 'should default proxy `delete` request' do
    stop_api = MockWebService::Server.start(@options, Proc.new(){[200, {}, []]})

    mock.set_proxy :delete, '/abc', 'http://0.0.0.0:1926/'

    # make HTTP request to API
    response = HTTParty.delete "#{url}/abc"

    # assert response code 200
    expect(response.code).to be 200

    # assert response body is equal to expected
    expect(response.body).to eql ''

    stop_api.call
  end
  
  it 'should return 404 if request made to different verb' do
    stop_api = MockWebService::Server.start(@options, Proc.new(){[200, {}, ['OK!!!']]})

    mock.set_proxy :get, '/abc', 'http://0.0.0.0:1926/'

    # make HTTP request to API
    response = HTTParty.put "#{url}/abc", body: 'ABC'

    # assert response code 404
    expect(response.code).to be 404

    stop_api.call
  end
  
  it 'should allow requests from all verbs if none specified' do
    count = 0

    stop_api = MockWebService::Server.start(@options, Proc.new(){|env|
      req = Rack::Request.new env
      count += 1

      case count
      when 1
        expect(req.request_method).to eql 'GET'
        expect(req.body.read).to eql ''
        [200, {}, ['GET!!!']]
      when 2
        expect(req.request_method).to eql 'POST'
        expect(req.body.read).to eql 'ABC'
        [200, {}, ['POST!!!']]
      when 3
        expect(req.request_method).to eql 'PUT'
        expect(req.body.read).to eql 'ABC'
        [200, {}, ['PUT!!!']]
      when 4
        expect(req.request_method).to eql 'DELETE'
        expect(req.body.read).to eql ''
        [200, {}, ['DELETE!!!']]
      end
    })
      
    mock.set_proxy '/abc', 'http://0.0.0.0:1926/'

    response = HTTParty.get "#{url}/abc"
    expect(response.code).to be 200
    expect(response.body).to eql 'GET!!!'

    response = HTTParty.post "#{url}/abc", { body: 'ABC' }
    expect(response.code).to be 200
    expect(response.body).to eql 'POST!!!'
    
    response = HTTParty.put "#{url}/abc", { body: 'ABC' }
    expect(response.code).to be 200
    expect(response.body).to eql 'PUT!!!'

    response = HTTParty.delete "#{url}/abc"
    expect(response.code).to be 200
    expect(response.body).to eql 'DELETE!!!'

    stop_api.call
  end
  
  it 'should allow other stubbed endpoints' do
    stop_api = MockWebService::Server.start(@options, Proc.new(){[200, {}, ['OK!!!']]})
    mock.set_proxy :get, '/abc', 'http://0.0.0.0:1926/'
    mock.get('/def') {[200, {}, 'HANDLED!!!']}

    # make HTTP request to API
    response = HTTParty.get "#{url}/abc"
    # assert response code 200
    expect(response.code).to be 200
    # assert response body is equal to expected
    expect(response.body).to eql 'OK!!!'

    # make HTTP request to API
    response = HTTParty.get "#{url}/def"
    # assert response code 200
    expect(response.code).to be 200
    # assert response body is equal to expected
    expect(response.body).to eql 'HANDLED!!!'

    stop_api.call
  end
end
