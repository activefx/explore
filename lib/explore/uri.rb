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

    # Forward missing methods to @uri
    def method_missing(method_name, *args, &block)
      if uri.respond_to?(method_name)
        uri.send(method_name, *args, &block)
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
