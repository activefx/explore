# frozen_string_literal: true
module Explore
  class Resource
    attr_reader :uri, :domain

    def initialize(input)
      @uri = Explore::URI.new(input)
      @domain = Explore::Domain.new(@uri.host, ignore_private: true)
    end
  end
end
