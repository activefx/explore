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

# Explore is a Ruby library for exploring web resources via HTTP requests,
# parsing URIs, and analyzing website metadata.
module Explore
  class << self
    def new(uri, **)
      Resource.new(uri, **)
    end
  end
end
