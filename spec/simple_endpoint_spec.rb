require 'mock_web_service'

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
end
