# frozen_string_literal: true

module Explore
  # The Head class performs HEAD requests to URLs and provides methods to inspect
  # the response headers and status information.
  class Head
    # Default options for HEAD requests
    DEFAULT_OPTIONS = {
      method: :head,
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

    # @return [Explore::Request] The underlying request object
    attr_reader :request

    # Initialize a new Head request
    #
    # @param uri [String] The URI to send the HEAD request to
    # @raise [URI::InvalidURIError] If the URI is invalid
    def initialize(uri, options = {})
      @uri = uri
      @options = DEFAULT_OPTIONS.deep_merge(options)
      @request = nil
      @errors = []

      begin
        @request = Explore::Request.new(uri, **options)
      rescue Explore::TimeoutError, Explore::RequestError => e
        @errors << e.message
      end
    end

    def response
      @request.response
    end

    # Get the final URL after any redirects
    #
    # @return [String] The final URL
    def url
      @request ? response.env.url.to_s : @uri.to_s
    end

    # Check if the request was successful
    #
    # @return [Boolean] true if the status code is in the 2xx range
    def success?
      @request && response.success?
    end

    # Get the HTTP status code
    #
    # @return [Integer] The HTTP status code
    def status_code
      @request ? response.status : 0
    end

    # Get the HTTP status text
    #
    # @return [String] The HTTP status text (reason phrase)
    def status_text
      @request ? response.reason_phrase : ""
    end

    # Get the response headers
    #
    # @return [Hash] The response headers
    def headers
      @request ? response.headers : {}
    end

    def content_type
      response[:content_type]
    end

    def content_encoding
      response[:content_encoding]
    end

    def last_modified
      Time.parse(response[:last_modified]).to_s
    rescue ArgumentError, TypeError
      nil
    end

    # Get the errors that occurred during initialization
    #
    # @return [Array] The errors
    attr_reader :errors
  end
end
