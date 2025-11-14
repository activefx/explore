# frozen_string_literal: true

module Explore
  # Performs HTTP HEAD requests to URLs and provides convenient access to response
  # headers and status information.
  #
  # The Head class wraps the lower-level Request class and provides sensible defaults
  # for HEAD requests, including automatic redirect following, timeouts, and retries.
  # It gracefully handles errors by capturing them in an errors array rather than raising.
  #
  # @example Basic usage with a string URL
  #   head = Explore::Head.new("https://example.com")
  #   head.success?       # => true
  #   head.status_code    # => 200
  #   head.content_type   # => "text/html"
  #
  # @example Using with an Explore::URI object (avoids reparsing)
  #   uri = Explore::URI.new("https://example.com")
  #   head = Explore::Head.new(uri)
  #
  # @example With custom options
  #   head = Explore::Head.new("https://example.com",
  #                            connection_timeout: 10,
  #                            retries: 5)
  #
  # @example Handling redirects
  #   head = Explore::Head.new("http://github.com")
  #   head.uri.to_s  # => "https://github.com/" (final URL after redirect)
  #
  # @example Error handling
  #   head = Explore::Head.new("https://non-existent-domain.com")
  #   head.success?  # => false (or nil)
  #   head.errors    # => ["Connection failed: ..."]
  class Head
    # Default options for HEAD requests
    #
    # These options are merged with any custom options passed to the initializer.
    # Custom options will override defaults via deep merge.
    #
    # @return [Hash] frozen hash of default options
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

    # @return [Explore::Request, nil] The underlying request object, or nil if request failed
    attr_reader :request

    # Initialize a new Head request
    #
    # This method creates a HEAD request to the specified URI with the given options.
    # If the URI is already an Explore::URI object, it will be used directly without
    # reparsing. Errors during the request are caught and stored in the {#errors} array
    # rather than being raised.
    #
    # @param uri [Explore::URI, String] The URI to send the HEAD request to
    # @param options [Hash] Options to customize the request behavior
    # @option options [Integer] :connection_timeout Seconds to wait for connection (default: 5)
    # @option options [Integer] :read_timeout Seconds to wait for response (default: 10)
    # @option options [Integer] :retries Number of retry attempts (default: 2)
    # @option options [Boolean] :allow_redirections Whether to follow redirects (default: true)
    # @option options [Hash] :faraday_options Additional options passed to Faraday
    # @option options [Hash] :headers Custom HTTP headers to send with the request
    #
    # @example Basic usage
    #   head = Head.new("https://example.com")
    #
    # @example With custom timeout
    #   head = Head.new("https://example.com", connection_timeout: 10)
    #
    # @example Disable redirects
    #   head = Head.new("https://example.com", allow_redirections: false)
    def initialize(uri, options = {})
      @options = DEFAULT_OPTIONS.deep_merge(options)
      @request = nil
      @errors = []

      begin
        @request = Explore::Request.new(uri, **@options)
      rescue Explore::TimeoutError, Explore::RequestError => e
        @errors << e.message
      end
    end

    # Get the final URI after any redirects
    #
    # If the HEAD request followed redirects, this returns the final destination URI.
    # If the request failed, this returns nil.
    #
    # @return [Explore::URI, nil] The final URI after redirects, or nil if request failed
    #
    # @example Get final URL after redirect
    #   head = Head.new("http://github.com")
    #   head.uri.to_s  # => "https://github.com/"
    def uri
      @request&.url
    end

    # The following methods are delegated to the underlying request object.
    # They will return nil if the request failed (due to allow_nil: true).
    #
    # @!method response
    #   Get the raw Faraday response object
    #   @return [Faraday::Response, nil]
    #
    # @!method success?
    #   Check if the request returned a 2xx status code
    #   @return [Boolean, nil]
    #
    # @!method status_code
    #   Get the HTTP status code
    #   @return [Integer, nil]
    #
    # @!method status_text
    #   Get the HTTP status reason phrase
    #   @return [String, nil]
    #
    # @!method headers
    #   Get all response headers
    #   @return [Faraday::Utils::Headers, nil]
    #
    # @!method content_type
    #   Get the Content-Type header value
    #   @return [String, nil]
    #
    # @!method content_encoding
    #   Get the Content-Encoding header value
    #   @return [String, nil]
    #
    # @!method last_modified
    #   Get the Last-Modified header value as a parsed time string
    #   @return [String, nil]
    delegate :response, :success?, :status_code, :status_text, :headers,
             :content_type, :content_encoding, :last_modified,
             to: :request, allow_nil: true

    # Get the errors that occurred during request initialization or execution
    #
    # When a HEAD request fails due to network errors, timeouts, or other issues,
    # the error messages are captured here instead of being raised as exceptions.
    # This allows for graceful error handling in client code.
    #
    # @return [Array<String>] Array of error messages, empty if no errors occurred
    #
    # @example Check for errors
    #   head = Head.new("https://non-existent.com")
    #   if head.errors.any?
    #     puts "Errors: #{head.errors.join(', ')}"
    #   end
    attr_reader :errors
  end
end
