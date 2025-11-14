# frozen_string_literal: true

require "addressable/uri"

module Explore
  class URI
    attr_reader :uri

    def initialize(uri)
      @uri = Addressable::URI.parse(uri)
    end

    def to_s
      uri.to_s
    end

    # Returns the origin of the URI according to RFC 6454 section 6.2, with one modification:
    # While Addressable::URI parsing returns "null" for relative URIs, this method returns
    # nil instead for more idiomatic Ruby usage.
    #
    # @return [String, nil] The URI origin or nil for relative URIs
    # @see https://tools.ietf.org/html/rfc6454#section-6.2
    def origin
      if uri.origin == "null"
        nil
      else
        uri.origin
      end
    end

    # Forward missing methods to @uri
    def method_missing(method_name, *, &)
      if uri.respond_to?(method_name)
        uri.send(method_name, *, &)
      else
        super
      end
    end

    # Required companion to method_missing
    def respond_to_missing?(method_name, include_private = false)
      uri.respond_to?(method_name, include_private) || super
    end
  end
end
