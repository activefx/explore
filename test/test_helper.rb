$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "explore"
require "minitest/autorun"
require "minitest/pride"
require "minitest/reporters"
require_relative "support/vcr"

# Configure Minitest reporters
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
