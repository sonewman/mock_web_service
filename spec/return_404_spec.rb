require 'mock_web_service'

include MockWebService

host_name = '0.0.0.0'
port = 1925
endpoint = '/endpoint/to/test'

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

  it 'should return 404 if no route is set' do
    # make HTTP request to server
    response = HTTParty.get test_path

    # assert response code 500
    expect(response.code).to be 404

    requests = mock.log(:get, endpoint)

    expect(requests.length).to be 1
  end
end
