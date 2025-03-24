# frozen_string_literal: true

require_relative "explore/version"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "uri" => "URI"
)
loader.setup

module Explore
  class Error < StandardError; end

  class << self
    def new(uri)
      Resource.new(uri)
    end
  end
end
