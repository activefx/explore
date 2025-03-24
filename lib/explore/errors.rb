module Explore
  class Error < StandardError; end

  class RequestError < Error; end

  class TimeoutError < Error; end

  class ConnectionError < Error; end
end
