require 'mock_web_service'

include MockWebService

host_name = '0.0.0.0'
port = 1925
endpoint = '/endpoint/to/test'
response_body = 'OK!!!'

url = "http://#{host_name}:#{port}"
full_path = "#{url}#{endpoint}"
test_path = "#{full_path}?query=test"

describe MockWebService do
  before :each do
    mock.start host_name, port
  end

  after :each do
    mock.stop
  end
  
  it 'should allow a mock endpoint to be created and return expected on request' do

    h = Hash.new

    # set up mock endpoint
    mock.get endpoint do |request|
      expect(request.query).to eql h
      [200, response_body]
    end

    # make HTTP request to API
    response = HTTParty.get full_path

    # assert response code 200
    expect(response.code).to be 200

    requests = mock.log(:get, endpoint)
    expect(requests.length).to be 1

    # assert response body is equal to expected
    expect(response.body).to eql 'OK!!!'
  end

  it 'should return 404 if no route is set' do
    # make HTTP request to server
    response = HTTParty.get test_path

    # assert response code 500
    expect(response.code).to be 404
    
    requests = mock.log(:get, endpoint)

    expect(requests.length).to be 1
  end
  
  it 'reset should remove any set routes' do
    # set up mock endpoint
    mock.get endpoint do
      [200]
    end

    mock.reset

    # make HTTP request to server
    response = HTTParty.get full_path

    # assert response code 500
    expect(response.code).to be 404
  end

  it 'should match a url without specifying a querystring while requesting with one' do
    # set up mock endpoint
    mock.get endpoint do |request|
      expect(request.query).to eql 'query' => 'test'
      [200, response_body]
    end

    # make HTTP request to API
    response = HTTParty.get test_path

    # assert response code 200
    expect(response.code).to be 200

    request = mock.log(:get, endpoint).last

    # assert query is equal to expected
    expect(request.query).to eql 'query' => 'test'

    # assert response body is equal to expected
    expect(response.body).to eql 'OK!!!'
  end

  it 'should get all the history of requests under the url provided' do
    mock.get endpoint do |request|
      [200, response_body]
    end

    res1 = HTTParty.get "#{full_path}?a=1"
    res2 = HTTParty.get "#{full_path}?b=2"
    res3 = HTTParty.get "#{full_path}?c=3"

    requests = mock.log(:get, endpoint)

    expect(requests.length).to be 3

    req1 = requests[0]
    expect(req1.path).to eql endpoint
    expect(req1.query).to eql({ 'a' => '1' })
    expect(res1.code).to eql 200
    expect(res1.body).to eql req1.response.body

    req2 = requests[1]
    expect(req2.path).to eql endpoint
    expect(req2.query).to eql({ 'b' => '2' })
    expect(res2.code).to eql 200
    expect(res2.body).to eql req2.response.body

    req3 = requests[2]
    expect(req3.path).to eql endpoint
    expect(req3.query).to eql({ 'c' => '3' })
    expect(res3.code).to eql 200
    expect(res3.body).to eql req3.response.body
  end

  it 'should match routes with parameters' do
    # set up mock endpoint
    mock.get '/route/:test' do |request|
      expect(request.params).to eql :test => 'working'
      [200, response_body]
    end

    # make HTTP request to API
    response = HTTParty.get "#{url}/route/working"

    # assert response code 200
    expect(response.code).to be 200

    request = mock.log(:get, '/route/working').last

    # assert query is equal to expected
    expect(request.params).to eql :test => 'working'

    # assert response body is equal to expected
    expect(response.body).to eql 'OK!!!'
  end
end
