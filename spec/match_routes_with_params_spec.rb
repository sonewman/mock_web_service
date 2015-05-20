require 'mock_web_service'
#require 'sinatra/base'

include MockWebService

host_name = '0.0.0.0'
port = 1925
endpoint = '/endpoint/to/test'
response_body = 'OK!!!'

url = "http://#{host_name}:#{port}"
full_path = "#{url}#{endpoint}"

describe MockWebService do
  before :each do
    mock.start host_name, port
  end

  after :each do
    mock.stop
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
