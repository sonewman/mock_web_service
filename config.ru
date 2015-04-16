require 'mock_web_service'

mock = MockWebService::Service.new

mock.get '/' do
  'OK!!!'
end

run mock.app
