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
end
