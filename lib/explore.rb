# frozen_string_literal: true

require_relative "explore/version"
require "zeitwerk"

Zeitwerk::Loader.for_gem.setup

module Explore
  class Error < StandardError; end

  class << self
    def new(uri)
      Resource.new(uri)
    end
  end
end
