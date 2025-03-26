# frozen_string_literal: true

require_relative "explore/version"
require_relative "explore/errors"
require "zeitwerk"
require "active_support/all"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "uri" => "URI"
)
loader.setup

module Explore
  class << self
    def new(uri)
      Resource.new(uri)
    end
  end
end
