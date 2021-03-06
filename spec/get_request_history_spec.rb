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
end
