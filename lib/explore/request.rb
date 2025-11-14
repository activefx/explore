# frozen_string_literal: true

require "faraday"
require "faraday-cookie_jar"
require "faraday-http-cache"
require "faraday/encoding"
require "faraday/follow_redirects"
require "faraday/gzip"
require "faraday/retry"
require "timeout"

module Explore
  # HTTP request handler with support for redirects, retries, and various configuration options.
  #
  # This class provides a high-level interface for making HTTP requests using Faraday.
  # It handles timeouts, redirects, retries, custom headers, and various HTTP methods.
  # The request is executed immediately upon initialization to fail fast on errors.
  #
  # @example Simple GET request
  #   request = Explore::Request.new("https://example.com")
  #   request.read  # => HTML content
  #
  # @example HEAD request with redirects
  #   request = Explore::Request.new("http://example.com",
  #     method: :head,
  #     allow_redirections: true
  #   )
  #   request.response_url  # => "https://example.com" (after redirect)
  #
  # @example POST request with body
  #   request = Explore::Request.new("https://api.example.com/data",
  #     method: :post,
  #     body: JSON.generate({key: "value"}),
  #     headers: {"Content-Type" => "application/json"}
  #   )
  #
  # @example With timeouts and retries
  #   request = Explore::Request.new("https://example.com",
  #     connection_timeout: 5,
  #     read_timeout: 10,
  #     retries: 3
  #   )
  class Request
    # Allowed URI schemes for requests
    ALLOWED_SCHEMES = Set.new %w[http https]

    # Allowed HTTP methods
    ALLOWED_METHODS = Set.new %i[get post put delete head patch options trace]

    # HTTP methods that support request bodies
    BODY_METHODS = Set.new %i[post put patch]

    # @return [Explore::URI] The request URL (updated to final URL after redirects)
    attr_reader :url

    # Creates a new HTTP request and executes it immediately.
    #
    # The request is executed during initialization to fail fast on errors.
    # If redirects are allowed and followed, the url attribute will be updated
    # to reflect the final destination URL.
    #
    # @param initial_url [String, Explore::URI] The URL to request
    # @param options [Hash] Request configuration options
    #
    # @option options [Symbol] :method (:get) HTTP method to use
    # @option options [String] :body Request body (for POST, PUT, PATCH)
    # @option options [Boolean] :allow_redirections (false) Whether to follow redirects
    # @option options [Integer] :connection_timeout Timeout for establishing connection
    # @option options [Integer] :read_timeout Timeout for reading response
    # @option options [Integer] :retries Number of retry attempts on failure
    # @option options [String] :encoding Character encoding for response body
    # @option options [Hash] :headers Custom HTTP headers
    # @option options [Hash] :faraday_options Additional Faraday configuration
    # @option options [Hash] :faraday_http_cache HTTP caching configuration
    # @option options [Proc] :on_data Callback for streaming response data
    #
    # @raise [Explore::RequestError] If the URL scheme is not HTTP/HTTPS,
    #   if the HTTP method is invalid, or on connection/SSL errors
    # @raise [Explore::TimeoutError] If the request times out
    #
    # @example Basic request
    #   request = Explore::Request.new("https://example.com")
    #
    # @example With all options
    #   request = Explore::Request.new("https://example.com",
    #     method: :get,
    #     allow_redirections: true,
    #     connection_timeout: 5,
    #     read_timeout: 10,
    #     retries: 3,
    #     encoding: "UTF-8",
    #     headers: {"User-Agent" => "MyBot/1.0"}
    #   )
    def initialize(initial_url, options = {})
      @url = initial_url.is_a?(Explore::URI) ? initial_url : Explore::URI.new(initial_url)
      @method = options[:method] || :get

      raise Explore::RequestError, "URL must be HTTP" unless ALLOWED_SCHEMES.include?(url.scheme)
      raise Explore::RequestError, "Invalid HTTP method: #{@method}" unless ALLOWED_METHODS.include?(@method)

      @body               = options[:body]
      @allow_redirections = options[:allow_redirections]
      @connection_timeout = options[:connection_timeout]
      @read_timeout       = options[:read_timeout]
      @retries            = options[:retries]
      @encoding           = options[:encoding]
      @headers            = options[:headers]
      @faraday_options    = options[:faraday_options] || {}
      @faraday_http_cache = options[:faraday_http_cache]
      @on_data            = options[:on_data]

      response # request early so we can fail early
    end

    # Reads and returns the response body with optional encoding conversion.
    #
    # If an encoding was specified in the options, the body will be transcoded
    # to that encoding with invalid characters replaced. Null bytes are stripped
    # from the result.
    #
    # @return [String, nil] The response body or nil if no response
    # @raise [Explore::RequestError] If encoding conversion fails
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.read  # => "<!doctype html>..."
    #
    # @example With encoding
    #   request = Explore::Request.new("https://example.com", encoding: "UTF-8")
    #   request.read  # => UTF-8 encoded content
    def read
      return unless response

      body = response.body
      body = body.encode!(@encoding, @encoding, invalid: :replace) if @encoding
      body.tr("\000", "")
    rescue ArgumentError => e
      raise Explore::RequestError, e
    end

    # Returns the Faraday response object.
    #
    # The response is cached after the first request. This method handles
    # various error conditions and converts them to appropriate Explore errors.
    #
    # @return [Faraday::Response] The HTTP response object
    # @raise [Explore::TimeoutError] If the request times out
    # @raise [Explore::RequestError] On connection, SSL, or redirect errors
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.response.status  # => 200
    def response
      @response ||= fetch
    rescue Faraday::TimeoutError => e
      raise Explore::TimeoutError, e
    rescue Faraday::ConnectionFailed, Faraday::SSLError, ::URI::InvalidURIError,
           Faraday::FollowRedirects::RedirectLimitReached => e
      raise Explore::RequestError, e
    end

    # Returns the raw response body.
    #
    # Unlike {#read}, this method returns the body without any encoding
    # conversion or null byte stripping.
    #
    # @return [String] The raw response body
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.body  # => "<!doctype html>..."
    def body
      response.body
    end

    # Returns the final URL after following any redirects.
    #
    # If redirections were not allowed, this will be the same as the original URL.
    #
    # @return [String] The final URL
    #
    # @example
    #   request = Explore::Request.new("http://github.com", allow_redirections: true)
    #   request.response_url  # => "https://github.com/"
    def response_url
      response.env.url.to_s
    end

    # Checks if the request was successful (2xx status code).
    #
    # @return [Boolean] true if the status code is in the 2xx range
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.success?  # => true
    def success?
      response.success?
    end

    # Returns the HTTP status code of the response.
    #
    # @return [Integer] The HTTP status code
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.status_code  # => 200
    def status_code
      response.status
    end

    # Returns the HTTP status text (reason phrase).
    #
    # @return [String] The HTTP status text
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.status_text  # => "OK"
    def status_text
      response.reason_phrase
    end

    # Returns the response headers.
    #
    # @return [Hash] The response headers
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.headers["Content-Type"]  # => "text/html"
    def headers
      response.headers
    end

    # Returns the Content-Type header value.
    #
    # @return [String, nil] The content type with charset if present
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.content_type  # => "text/html; charset=UTF-8"
    def content_type
      response[:content_type]
    end

    # Returns the media type portion of the Content-Type header.
    #
    # Extracts just the MIME type, excluding any parameters like charset.
    #
    # @return [String, nil] The media type or nil if no content type
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.media_type  # => "text/html"
    def media_type
      content_type ? content_type.split(";")[0] : nil
    end

    # Extracts the charset from the Content-Type header.
    #
    # Maps common charset aliases (e.g., "utf8" to "utf-8") for consistency.
    #
    # @return [String, nil] The charset or nil if not specified
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.charset  # => "utf-8"
    def charset
      return unless content_type && content_type.include?(";")

      parts = content_type.split(";")[1..]
      charset_part = parts.find { |part| part.match?(/charset=/) }
      return unless charset_part

      return unless /charset=([^;|$]+)/.match(charset_part)

      { "utf8" => "utf-8" }.fetch(Regexp.last_match(1).strip, Regexp.last_match(1).strip)
    end

    # Returns the Content-Length header value.
    #
    # @return [String, nil] The content length
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.content_length  # => "1256"
    def content_length
      response[:content_length]
    end

    # Returns the Content-Encoding header value.
    #
    # @return [String, nil] The content encoding (e.g., "gzip")
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.content_encoding  # => "gzip"
    def content_encoding
      response[:content_encoding]
    end

    # Returns the Last-Modified header value as a string.
    #
    # @return [String, nil] The last modified date/time or nil if not present or invalid
    #
    # @example
    #   request = Explore::Request.new("https://example.com")
    #   request.last_modified  # => "2023-01-15 10:30:00 UTC"
    def last_modified
      Time.parse(response[:last_modified]).to_s
    rescue ArgumentError, TypeError
      nil
    end

    private

    # Executes the HTTP request using Faraday.
    #
    # Configures the Faraday connection with all specified middleware including
    # retries, gzip compression, redirects, caching, and custom headers.
    # Wraps the request in a timeout to handle streaming responses.
    #
    # @return [Faraday::Response] The HTTP response
    # @raise [Explore::TimeoutError] If the overall request times out
    # @api private
    def fetch
      Timeout.timeout(fatal_timeout) do
        @faraday_options.merge!(url: url)
        follow_redirects_options = @faraday_options.delete(:redirect) || {}

        session = Faraday.new(@faraday_options) do |faraday|
          faraday.request :retry, max: @retries

          faraday.request :gzip

          if @allow_redirections && method_redirects?
            follow_redirects_options[:limit] ||= 5
            faraday.use Faraday::FollowRedirects::Middleware, **follow_redirects_options
            faraday.use :cookie_jar
          end

          if @faraday_http_cache.is_a?(Hash)
            @faraday_http_cache[:serializer] ||= Marshal
            faraday.use Faraday::HttpCache, **@faraday_http_cache
          end

          faraday.headers.merge!(@headers || {})
          faraday.response :encoding
          faraday.adapter :net_http
        end

        # Allows the :on_data callback to abort the request
        response = catch(:abort) do
          session.send(@method) do |req|
            req.options.timeout      = @connection_timeout
            req.options.open_timeout = @read_timeout
            req.options.on_data      = @on_data if @on_data
            req.body                 = @body if method_body?
          end
        end

        @url = Explore::URI.new(response.env.url.to_s) if @allow_redirections

        response
      end
    rescue Timeout::Error => e
      raise Explore::TimeoutError, e
    end

    # Checks if the current HTTP method supports redirects.
    #
    # @return [Boolean] true if the method can follow redirects
    # @api private
    def method_redirects?
      Faraday::FollowRedirects::Middleware::ALLOWED_METHODS.include?(@method)
    end

    # Checks if the current HTTP method supports a request body.
    #
    # @return [Boolean] true if the method should include the body
    # @api private
    def method_body?
      @body && BODY_METHODS.include?(@method)
    end

    # Calculates the fatal timeout for streaming responses.
    #
    # Timeouts when connecting/reading a request are handled by Faraday, but in the
    # case of URLs that respond with streaming, Faraday will never return. In that case,
    # we resort to our own timeout that's slightly longer than the combined Faraday timeouts.
    #
    # @return [Integer] The timeout in seconds
    # @api private
    # @see https://github.com/jaimeiniesta/metainspector/issues/188
    # @see https://github.com/lostisland/faraday/issues/602
    def fatal_timeout
      (@connection_timeout || 0) + (@read_timeout || 0) + 1
    end
  end
end

# Originally from MetaInspector - MIT License
# Source: https://github.com/jaimeiniesta/metainspector/blob/master/lib/meta_inspector/request.rb
# Copyright (c) 2009-2013 Jaime Iniesta
