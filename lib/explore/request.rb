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
  # Makes the request to the server
  class Request
    ALLOWED_SCHEMES = Set.new %w[http https]
    ALLOWED_METHODS = Set.new %i[get post put delete head patch options trace]
    BODY_METHODS = Set.new %i[post put patch]

    attr_reader :url

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

    def read
      return unless response

      body = response.body
      body = body.encode!(@encoding, @encoding, invalid: :replace) if @encoding
      body.tr("\000", "")
    rescue ArgumentError => e
      raise Explore::RequestError, e
    end

    # def content_type
    #   return nil if response.headers['content-type'].nil?
    #   response.headers['content-type'].split(';')[0] if response
    # end

    def response
      @response ||= fetch
    rescue Faraday::TimeoutError => e
      raise Explore::TimeoutError, e
    rescue Faraday::ConnectionFailed, Faraday::SSLError, ::URI::InvalidURIError,
           Faraday::FollowRedirects::RedirectLimitReached => e
      raise Explore::RequestError, e
    end

    def body
      response.body
    end

    # Get the final URL after any redirects
    #
    # @return [String] The final URL
    def response_url
      response.env.url.to_s
    end

    # Check if the request was successful
    #
    # @return [Boolean] true if the status code is in the 2xx range
    def success?
      response.success?
    end

    # Get the HTTP status code
    #
    # @return [Integer] The HTTP status code
    def status_code
      response.status
    end

    # Get the HTTP status text
    #
    # @return [String] The HTTP status text (reason phrase)
    def status_text
      response.reason_phrase
    end

    # Get the response headers
    #
    # @return [Hash] The response headers
    def headers
      response.headers
    end

    def content_type
      response[:content_type]
    end

    def media_type
      content_type ? content_type.split(";")[0] : nil
    end

    def charset
      return unless /charset=([^;|$]+)/.match(content_type.split(";")[1])

      { "utf8" => "utf-8" }.fetch(Regexp.last_match(1), Regexp.last_match(1))
    end

    def content_length
      response[:content_length]
    end

    def content_encoding
      response[:content_encoding]
    end

    def last_modified
      Time.parse(response[:last_modified]).to_s
    rescue ArgumentError, TypeError
      nil
    end

    private

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

    def method_redirects?
      Faraday::FollowRedirects::Middleware::ALLOWED_METHODS.include?(@method)
    end

    def method_body?
      @body && BODY_METHODS.include?(@method)
    end

    # Timeouts when connecting / reading a request are handled by Faraday, but in the
    # case of URLs that respond with streaming, Faraday will never return. In that case,
    # we'll resort to our own timeout
    #
    # https://github.com/jaimeiniesta/metainspector/issues/188
    # https://github.com/lostisland/faraday/issues/602
    #
    def fatal_timeout
      (@connection_timeout || 0) + (@read_timeout || 0) + 1
    end
  end
end

# Originally from MetaInspector - MIT License
# Source: https://github.com/jaimeiniesta/metainspector/blob/master/lib/meta_inspector/request.rb
# Copyright (c) 2009-2013 Jaime Iniesta
