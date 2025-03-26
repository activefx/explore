require "gort"

module Explore
  # Handles parsing and interpretation of robots.txt files
  # This class provides functionality to fetch, parse and analyze robots.txt files
  # from websites using the Gort parser.
  #
  # @example
  #   robots = Explore::Robots.new(uri: "https://example.com/robots.txt")
  #   robots.sitemaps # => ["https://example.com/sitemap.xml"]
  class Robots
    # Default HTTP request options for fetching robots.txt
    DEFAULT_OPTIONS = {
      method: :get,
      allow_redirections: true,
      connection_timeout: 5,
      read_timeout: 10,
      retries: 2,
      faraday_options: {
        redirect: {
          limit: 3
        }
      }
    }.freeze

    # @return [Gort::RobotsTxt] The parsed robots.txt content
    attr_reader :robots_txt

    # @return [Array<String>] Collection of errors encountered during processing
    attr_reader :errors

    # Initialize a new Robots instance
    #
    # @param uri [String, nil] The URI of the robots.txt file to fetch
    # @param contents [String, nil] Direct robots.txt contents to parse
    # @raise [Explore::TimeoutError] When the request times out
    # @raise [Explore::RequestError] When the request fails
    def initialize(uri: nil, contents: nil)
      @errors = []
      if contents
        @contents = contents
      else
        @uri = uri
        response
        @contents = errors.empty? ? @request.body : ""
      end
      @robots_txt = Gort::Parser.new(@contents).parse
    end

    # Get all rules from the parsed robots.txt
    #
    # @return [Array<Gort::Rule>] Collection of parsed rules
    def rules
      @robots_txt.rules
    end

    # Extract sitemap URLs from the robots.txt
    #
    # @return [Array<String>] Collection of sitemap URLs
    def sitemaps
      rules.select { |rule| rule.is_a?(Gort::Rule) && rule.name == :sitemap }.map(&:value)
    end

    private

    # Fetch the robots.txt content from the specified URI
    #
    # @return [Explore::Request] The HTTP response
    # @private
    def response
      begin
        @request = Explore::Request.new(@uri, **DEFAULT_OPTIONS)
      rescue Explore::TimeoutError, Explore::RequestError => e
        @errors << e.message
      end
    end
  end
end
