require 'mock_web_service'
include MockWebService

host_name = '0.0.0.0'
port = 1925
endpoint = '/endpoint/to/test'
response_body = 'OK!!!'

describe MockWebService do
  before :each do
    mock.start host_name, port
  end

  after :each do
    mock.stop
  end

  it 'should allow a mock endpoint to be created and return expected on request' do
    # set up mock endpoint
    mock.get endpoint do |request|
      [200, response_body]
    end

    # make HTTP request to Bridge API
    response = HTTParty.get "http://#{host_name}:#{port}#{endpoint}?query=test"

    # assert response code 200
    expect(response.code).to be 200

    request = mock.log(:get, endpoint).last

    # get request query string used on request
    query_string = CGI::parse(request.headers['QUERY_STRING'])

    # assert query is equal to expected
    expect(query_string).to eql 'query' => ['test']

    # assert response body is equal to expected
    expect(response.body).to eql 'OK!!!'
  end
end
