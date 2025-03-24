# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock

  # Allow requests to localhost and test servers to pass through
  config.ignore_localhost = true

  # Don't allow any HTTP requests without a matching cassette
  config.allow_http_connections_when_no_cassette = false

  # Remove sensitive data from VCR cassettes
  config.filter_sensitive_data("<API_KEY>") { ENV["API_KEY"] } if ENV["API_KEY"]

  # Ignore requests to Chrome browser when using system tests
  config.ignore_hosts "chromedriver.storage.googleapis.com"

  # Configure VCR to work with webdrivers gem
  config.ignore_request do |request|
    uri = URI(request.uri)
    # Ignore requests to common browser testing services
    uri.host =~ /\.(browserstack\.com|saucelabs\.com|selenium-grid\.com)$/
  end
end

# Helper method for tests
def with_vcr_cassette(name, **options)
  VCR.use_cassette(name, options) do
    yield
  end
end
