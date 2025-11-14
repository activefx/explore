# frozen_string_literal: true

require "gort"

module Explore
  # Handles parsing and interpretation of robots.txt files
  # This class provides functionality to fetch, parse and analyze robots.txt files
  # from websites using the Gort parser.
  #
  # @example Basic usage
  #   robots = Explore::Robots.new(uri: "https://example.com/robots.txt")
  #   robots.sitemaps # => ["https://example.com/sitemap.xml"]
  #
  # @example Checking if a path is allowed
  #   robots = Explore::Robots.new(contents: "User-agent: *\nDisallow: /private/")
  #   robots.allow?("MyBot", "/public/page")  # => true
  #   robots.disallow?("MyBot", "/private/data")  # => false
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

    # Delegate Gort::RobotsTxt methods to @robots_txt instance
    # @!method allow?(user_agent, path)
    #   Check if a path is allowed for a given user agent
    #   @param user_agent [String] The user agent to check
    #   @param path [String] The path to check (e.g., "/page" or "/page?query=string")
    #   @return [Boolean] true if the path is allowed
    # @!method disallow?(user_agent, path)
    #   Check if a path is disallowed for a given user agent
    #   @param user_agent [String] The user agent to check
    #   @param path [String] The path to check
    #   @return [Boolean] true if the path is disallowed
    # @!method rules
    #   Get all rules from the parsed robots.txt
    #   @return [Array<Gort::Rule, Gort::Group, Gort::InvalidLine>] Collection of parsed rules
    delegate :allow?, :disallow?, :rules, to: :robots_txt

    # Initialize a new Robots instance
    #
    # @param uri [String, nil] The URI of the robots.txt file to fetch
    # @param contents [String, nil] Direct robots.txt contents to parse
    # @param options [Hash] Custom HTTP request options (merged with DEFAULT_OPTIONS)
    # @option options [Integer] :connection_timeout Connection timeout in seconds
    # @option options [Integer] :read_timeout Read timeout in seconds
    # @option options [Integer] :retries Number of retry attempts
    # @note When fetching via URI, errors are captured in the {#errors} array rather than raised.
    #   Check {#errors} to see if the request failed.
    # @note Either uri or contents must be provided. If both are nil, an error is added to {#errors}.
    #
    # @example With custom timeout
    #   robots = Explore::Robots.new(uri: "https://example.com/robots.txt", connection_timeout: 10)
    #
    # @example With error checking
    #   robots = Explore::Robots.new(uri: "https://example.com/robots.txt")
    #   if robots.success?
    #     puts "Sitemaps: #{robots.sitemaps}"
    #   else
    #     puts "Errors: #{robots.errors.join(', ')}"
    #   end
    def initialize(uri: nil, contents: nil, **options)
      @errors = []
      @options = DEFAULT_OPTIONS.deep_merge(options)
      @contents = load_contents(uri, contents)
      @robots_txt = Gort::Parser.new(@contents).parse
    end

    # Check if robots.txt was successfully fetched and parsed
    #
    # @return [Boolean] true if no errors occurred during fetching or parsing
    #
    # @example
    #   robots = Explore::Robots.new(uri: "https://example.com/robots.txt")
    #   puts "Success!" if robots.success?
    def success?
      errors.empty?
    end

    # Extract sitemap URLs from the robots.txt
    #
    # @return [Array<String>] Collection of sitemap URLs (empty array if none found)
    #
    # @example
    #   robots.sitemaps  # => ["https://example.com/sitemap.xml", "https://example.com/sitemap2.xml"]
    #
    # @note Returns an empty array if robots.txt parsing failed or no sitemaps are declared
    def sitemaps
      rules.select { |rule| rule.is_a?(Gort::Rule) && rule.name == :sitemap }.map(&:value)
    end

    # Custom inspect for better debugging experience
    #
    # @return [String] A readable representation of the Robots instance
    def inspect
      "#<#{self.class.name} sitemaps=#{sitemaps.size} rules=#{rules.size} errors=#{errors.size}>"
    end

    private

    # Load robots.txt content from either direct contents or URI
    #
    # @param uri [String, nil] The URI to fetch from
    # @param contents [String, nil] Direct contents
    # @return [String] The robots.txt content
    # @private
    def load_contents(uri, contents)
      if contents
        contents
      elsif uri
        @uri = uri
        response
        errors.empty? ? @request.body : ""
      else
        @errors << "Either uri or contents must be provided"
        ""
      end
    end

    # Fetch the robots.txt content from the specified URI
    #
    # @return [Explore::Request] The HTTP response
    # @private
    def response
      @request = Explore::Request.new(@uri, **@options)
    rescue Explore::TimeoutError, Explore::RequestError => e
      @errors << e.message
    end
  end
end
