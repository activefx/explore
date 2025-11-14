# frozen_string_literal: true

require "public_suffix"

module Explore
  # The Domain class provides functionality for parsing and manipulating domain names
  # using the public_suffix library. It handles domain name components like TLD,
  # registered domain, and subdomains, with special handling for 'www' prefixes.
  class Domain
    attr_reader :domain, :options

    # Default options for domain parsing
    DEFAULT_OPTIONS = {
      ignore_private: true
    }.freeze

    # Initialize a new Domain instance
    # @param domain [String] The domain name to parse
    # @param options [Hash] Options to pass to PublicSuffix.parse
    # @option options [Boolean] :ignore_private Whether to ignore private domains (default: true)
    def initialize(domain, options = {})
      @options = DEFAULT_OPTIONS.merge(options)
      @domain = PublicSuffix.parse(domain, **DEFAULT_OPTIONS, **options)
    end

    # Returns the string representation of the domain
    # @return [String] The full domain name
    def to_s
      domain.to_s
    end

    # Returns the domain parts as an array
    # @return [Array<String>] Array of domain parts
    def to_a
      domain.to_a
    end

    # Returns the registered domain (domain without subdomains)
    # @return [String] The registered domain name
    def registered_domain
      domain.domain
    end

    # Extracts the 'www' prefix if present
    # @return [String, nil] The www prefix if present, nil otherwise
    def www
      domain.name.match(/(?<www>\Aw{2}(w|\d))\.+.+\./) { |m| m[:www] }
    end

    # Returns the domain name without the 'www' prefix
    # @return [String] Domain name without www prefix
    def key
      www ? domain.name.sub(/\A#{www}./, "") : domain.name
    end

    # Forward missing methods to @domain
    def method_missing(method_name, *, &)
      if domain.respond_to?(method_name)
        domain.send(method_name, *, &)
      else
        super
      end
    end

    # Required companion to method_missing
    def respond_to_missing?(method_name, include_private = false)
      domain.respond_to?(method_name, include_private) || super
    end
  end
end
