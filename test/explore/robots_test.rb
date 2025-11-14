# frozen_string_literal: true

require "test_helper"

module Explore
  class RobotsTest < ActiveSupport::TestCase
    def setup
      @valid_robots_content = <<~ROBOTS
        User-agent: *
        Disallow: /private/
        Allow: /public/
        Sitemap: https://example.com/sitemap.xml
        Sitemap: https://example.com/sitemap2.xml
      ROBOTS

      @robots = Robots.new(contents: @valid_robots_content)
    end

    test "initializes with direct contents" do
      assert_instance_of Robots, @robots
      assert_empty @robots.errors
    end

    test "initializes with URI" do
      uri = "https://example.com/robots.txt"
      mock_response = Minitest::Mock.new
      mock_response.expect :body, @valid_robots_content

      Explore::Request.stub :new, mock_response do
        robots = Robots.new(uri: uri)

        assert_instance_of Robots, robots
        assert_empty robots.errors
      end
    end

    test "handles request errors gracefully" do
      uri = "https://example.com/robots.txt"

      Explore::Request.stub :new, ->(*_args) { raise Explore::RequestError, "Failed to fetch" } do
        robots = Robots.new(uri: uri)

        assert_includes robots.errors, "Failed to fetch"
      end
    end

    test "handles timeout errors gracefully" do
      uri = "https://example.com/robots.txt"

      Explore::Request.stub :new, ->(*_args) { raise Explore::TimeoutError, "Request timed out" } do
        robots = Robots.new(uri: uri)

        assert_includes robots.errors, "Request timed out"
      end
    end

    test "extracts sitemaps correctly" do
      expected_sitemaps = [
        "https://example.com/sitemap.xml",
        "https://example.com/sitemap2.xml"
      ]

      assert_equal expected_sitemaps, @robots.sitemaps
    end

    test "handles empty robots.txt content" do
      robots = Robots.new(contents: "")

      assert_empty robots.sitemaps
      assert_empty robots.rules
    end

    test "handles malformed robots.txt content" do
      malformed_content = "Invalid content\nNot following robots.txt format"
      robots = Robots.new(contents: malformed_content)

      assert_empty robots.sitemaps
      assert_instance_of Array, robots.rules
    end

    test "DEFAULT_OPTIONS are frozen" do
      assert_predicate Robots::DEFAULT_OPTIONS, :frozen?
      assert_raises(FrozenError) { Robots::DEFAULT_OPTIONS[:method] = :post }
    end
  end
end
