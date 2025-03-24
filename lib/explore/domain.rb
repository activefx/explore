require "public_suffix"

module Explore
  class Domain
    attr_reader :domain, :options

    DEFAULT_OPTIONS = {
      ignore_private: true
    }.freeze

    def initialize(domain, options = {})
      @options = DEFAULT_OPTIONS.merge(options)
      @domain = PublicSuffix.parse(domain, **DEFAULT_OPTIONS.merge(options))
    end

    def to_s
      domain.to_s
    end

    def to_a
      domain.to_a
    end

    # Forward missing methods to @domain
    def method_missing(method_name, *args, &block)
      if domain.respond_to?(method_name)
        domain.send(method_name, *args, &block)
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
