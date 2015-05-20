require 'mock_web_service'

include MockWebService

host_name = '0.0.0.0'
port = 1925
endpoint = '/endpoint/to/test'

url = "http://#{host_name}:#{port}"
full_path = "#{url}#{endpoint}"

describe MockWebService do
  before :each do
    mock.start host_name, port
  end

  after :each do
    mock.stop
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
end
