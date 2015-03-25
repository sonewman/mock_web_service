require 'mock_web_service/version'
require 'mock_web_service/endpoints'
require 'mock_web_service/service'

module MockWebService
  def mock
    @mock ||= Service.new
  end
end
