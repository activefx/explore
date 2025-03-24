require 'faraday'
require 'faraday-cookie_jar'
require 'faraday-http-cache'
require 'faraday/encoding'
require 'faraday/follow_redirects'
require 'faraday/gzip'
require 'faraday/retry'
require 'timeout'

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

      fail Explore::RequestError.new('URL must be HTTP') unless ALLOWED_SCHEMES.include?(url.scheme)
      fail Explore::RequestError.new("Invalid HTTP method: #{@method}") unless ALLOWED_METHODS.include?(@method)

      @body               = options[:body]
      @allow_redirections = options[:allow_redirections]
      @connection_timeout = options[:connection_timeout]
      @read_timeout       = options[:read_timeout]
      @retries            = options[:retries]
      @encoding           = options[:encoding]
      @headers            = options[:headers]
      @faraday_options    = options[:faraday_options] || {}
      @faraday_http_cache = options[:faraday_http_cache]

      response            # request early so we can fail early
    end

    def read
      return unless response
      body = response.body
      body = body.encode!(@encoding, @encoding, invalid: :replace) if @encoding
      body.tr("\000", '')
    rescue ArgumentError => e
      raise Explore::RequestError.new(e)
    end

    def content_type
      return nil if response.headers['content-type'].nil?
      response.headers['content-type'].split(';')[0] if response
    end

    def response
      @response ||= fetch
    rescue Faraday::TimeoutError => e
      raise Explore::TimeoutError.new(e)
    rescue Faraday::ConnectionFailed, Faraday::SSLError, ::URI::InvalidURIError, Faraday::FollowRedirects::RedirectLimitReached => e
      raise Explore::RequestError.new(e)
    end

    private

    def fetch
      Timeout::timeout(fatal_timeout) do
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

        response = session.send(@method) do |req|
          req.options.timeout      = @connection_timeout
          req.options.open_timeout = @read_timeout
          req.body = @body if method_body?
        end

        if @allow_redirections
          @url = Explore::URI.new(response.env.url.to_s)
        end

        response
      end
    rescue Timeout::Error => e
      raise Explore::TimeoutError.new(e)
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
