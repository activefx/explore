# frozen_string_literal: true

require "addressable/uri"

module Explore
  # Wrapper class for URI parsing and manipulation.
  #
  # This class provides a Ruby-friendly interface to Addressable::URI with
  # improved handling of edge cases. It delegates most methods to the underlying
  # Addressable::URI instance while providing custom behavior for specific methods.
  #
  # The class automatically forwards unknown methods to the wrapped Addressable::URI
  # instance, providing transparent access to all Addressable::URI functionality.
  #
  # @example Basic usage
  #   uri = Explore::URI.new("https://example.com/path?query=value")
  #   uri.scheme    # => "https"
  #   uri.host      # => "example.com"
  #   uri.path      # => "/path"
  #   uri.query     # => "query=value"
  #
  # @example Accessing the origin
  #   uri = Explore::URI.new("https://example.com:8080/path")
  #   uri.origin    # => "https://example.com:8080"
  #
  # @example Handling relative URIs
  #   uri = Explore::URI.new("/path/to/resource")
  #   uri.origin    # => nil (instead of "null")
  #   uri.scheme    # => nil
  #   uri.path      # => "/path/to/resource"
  class URI
    # @return [Addressable::URI] the underlying Addressable::URI instance
    attr_reader :uri

    # Creates a new URI instance by parsing the input string.
    #
    # @param uri [String, Addressable::URI] the URI string to parse
    # @raise [Addressable::URI::InvalidURIError] if the URI is malformed
    #
    # @example Parse a simple URI
    #   uri = Explore::URI.new("https://example.com")
    #
    # @example Parse a complex URI with all components
    #   uri = Explore::URI.new("https://user:pass@example.com:8080/path?query=value#fragment")
    #
    # @example Parse a relative URI
    #   uri = Explore::URI.new("/path/to/resource")
    def initialize(uri)
      @uri = Addressable::URI.parse(uri)
    end

    # Returns the string representation of the URI.
    #
    # @return [String] the complete URI as a string
    #
    # @example
    #   uri = Explore::URI.new("https://example.com/path")
    #   uri.to_s  # => "https://example.com/path"
    def to_s
      uri.to_s
    end

    # Returns the origin of the URI according to RFC 6454 section 6.2.
    #
    # This method improves upon Addressable::URI's origin method by returning
    # nil instead of "null" for URIs that don't have a valid origin (such as
    # relative URIs, file URIs, and data URIs). This provides more idiomatic
    # Ruby usage.
    #
    # The origin consists of the scheme, host, and port (if non-default).
    #
    # @return [String, nil] the URI origin, or nil for relative URIs and
    #   URIs without a valid origin
    #
    # @example HTTP URI with default port
    #   uri = Explore::URI.new("https://example.com/path")
    #   uri.origin  # => "https://example.com"
    #
    # @example HTTP URI with custom port
    #   uri = Explore::URI.new("https://example.com:8080/path")
    #   uri.origin  # => "https://example.com:8080"
    #
    # @example Relative URI returns nil
    #   uri = Explore::URI.new("/path/to/resource")
    #   uri.origin  # => nil
    #
    # @example File URI returns nil
    #   uri = Explore::URI.new("file:///path/to/file")
    #   uri.origin  # => nil
    #
    # @see https://tools.ietf.org/html/rfc6454#section-6.2 RFC 6454 Section 6.2
    def origin
      if uri.origin == "null"
        nil
      else
        uri.origin
      end
    end

    # @!method scheme
    #   Returns the scheme component of the URI.
    #   @return [String, nil] the scheme (e.g., "https", "http") or nil for relative URIs
    #   @example
    #     uri = Explore::URI.new("https://example.com")
    #     uri.scheme  # => "https"

    # @!method host
    #   Returns the host component of the URI.
    #   @return [String, nil] the hostname or nil for relative URIs
    #   @example
    #     uri = Explore::URI.new("https://example.com")
    #     uri.host  # => "example.com"

    # @!method port
    #   Returns the port component of the URI.
    #   @return [Integer, nil] the port number or nil for default ports
    #   @example
    #     uri = Explore::URI.new("https://example.com:8080")
    #     uri.port  # => 8080

    # @!method path
    #   Returns the path component of the URI.
    #   @return [String] the path (empty string for root)
    #   @example
    #     uri = Explore::URI.new("https://example.com/path/to/resource")
    #     uri.path  # => "/path/to/resource"

    # @!method query
    #   Returns the query string component of the URI.
    #   @return [String, nil] the query string or nil if not present
    #   @example
    #     uri = Explore::URI.new("https://example.com?foo=bar&baz=qux")
    #     uri.query  # => "foo=bar&baz=qux"

    # @!method fragment
    #   Returns the fragment identifier component of the URI.
    #   @return [String, nil] the fragment or nil if not present
    #   @example
    #     uri = Explore::URI.new("https://example.com#section")
    #     uri.fragment  # => "section"

    # @!method userinfo
    #   Returns the userinfo component of the URI.
    #   @return [String, nil] the userinfo (e.g., "user:pass") or nil if not present
    #   @example
    #     uri = Explore::URI.new("https://user:pass@example.com")
    #     uri.userinfo  # => "user:pass"

    # @!method normalize
    #   Returns a normalized version of the URI.
    #   @return [Addressable::URI] normalized URI
    #   @example
    #     uri = Explore::URI.new("HTTPS://EXAMPLE.COM/PATH")
    #     uri.normalize  # => normalized Addressable::URI

    # Forwards method calls to the wrapped Addressable::URI instance.
    #
    # This enables transparent delegation of all Addressable::URI methods,
    # including scheme, host, port, path, query, fragment, userinfo, normalize,
    # and many others. All arguments and blocks are forwarded to the underlying
    # Addressable::URI instance.
    #
    # @return [Object] the result from the delegated method
    # @raise [NoMethodError] if the method doesn't exist on the wrapped URI
    #
    # @api private
    def method_missing(method_name, *, &)
      if uri.respond_to?(method_name)
        uri.send(method_name, *, &)
      else
        super
      end
    end

    # Checks if the URI instance responds to a method.
    #
    # Returns true for methods defined on this class or methods available
    # on the wrapped Addressable::URI instance.
    #
    # @param method_name [Symbol] the name of the method to check
    # @param include_private [Boolean] whether to include private methods
    # @return [Boolean] true if the instance responds to the method
    #
    # @api private
    def respond_to_missing?(method_name, include_private = false)
      uri.respond_to?(method_name, include_private) || super
    end
  end
end
