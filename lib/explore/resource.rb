# frozen_string_literal: true

require "addressable/uri"
require "public_suffix"

module Explore
  class Resource
    attr_reader :uri, :host

    def initialize(uri)
      @uri = Addressable::URI.parse(uri)
      @host = PublicSuffix.parse(@uri.host, ignore_private: true)
    end
  end
end
