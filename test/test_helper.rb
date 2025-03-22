require "minitest/autorun"
require "minitest/pride"
require "minitest/reporters"
require "explore"

# Configure Minitest reporters
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
