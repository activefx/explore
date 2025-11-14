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

    describe "parameter validation" do
      it "adds error when neither uri nor contents provided" do
        robots = Robots.new

        assert_includes robots.errors, "Either uri or contents must be provided"
        refute_predicate robots, :success?
      end

      it "succeeds with contents parameter" do
        robots = Robots.new(contents: "User-agent: *\nDisallow: /")

        assert_predicate robots, :success?
        assert_empty robots.errors
      end
    end

    describe "options customization" do
      it "accepts custom connection_timeout" do
        uri = "https://example.com/robots.txt"
        mock_response = Minitest::Mock.new
        mock_response.expect :body, ""

        Explore::Request.stub :new, lambda { |_url, **opts|
          assert_equal 15, opts[:connection_timeout]
          mock_response
        } do
          Robots.new(uri: uri, connection_timeout: 15)
        end

        mock_response.verify
      end

      it "accepts custom retries" do
        uri = "https://example.com/robots.txt"
        mock_response = Minitest::Mock.new
        mock_response.expect :body, ""

        Explore::Request.stub :new, lambda { |_url, **opts|
          assert_equal 5, opts[:retries]
          mock_response
        } do
          Robots.new(uri: uri, retries: 5)
        end

        mock_response.verify
      end

      it "merges custom options with DEFAULT_OPTIONS" do
        uri = "https://example.com/robots.txt"
        mock_response = Minitest::Mock.new
        mock_response.expect :body, ""

        Explore::Request.stub :new, lambda { |_url, **opts|
          # Check that default options are preserved
          assert_equal :get, opts[:method]
          assert opts[:allow_redirections]
          # Check that custom option is applied
          assert_equal 20, opts[:read_timeout]
          mock_response
        } do
          Robots.new(uri: uri, read_timeout: 20)
        end

        mock_response.verify
      end
    end

    describe "#success?" do
      it "returns true when no errors" do
        robots = Robots.new(contents: "User-agent: *\nDisallow: /")

        assert_predicate robots, :success?
      end

      it "returns false when errors exist" do
        robots = Robots.new

        refute_predicate robots, :success?
      end

      it "returns false after request failure" do
        uri = "https://example.com/robots.txt"

        Explore::Request.stub :new, ->(*_args) { raise Explore::RequestError, "Failed" } do
          robots = Robots.new(uri: uri)

          refute_predicate robots, :success?
        end
      end
    end

    describe "#inspect" do
      it "includes sitemap count" do
        robots = Robots.new(contents: "Sitemap: https://example.com/sitemap.xml")
        inspect_str = robots.inspect

        assert_includes inspect_str, "sitemaps=1"
      end

      it "includes rules count" do
        robots = Robots.new(contents: "User-agent: *\nDisallow: /admin/\nDisallow: /private/")
        inspect_str = robots.inspect

        assert_includes inspect_str, "rules="
        assert_match(/rules=\d+/, inspect_str)
      end

      it "includes errors count" do
        robots = Robots.new
        inspect_str = robots.inspect

        assert_includes inspect_str, "errors=1"
      end

      it "includes class name" do
        robots = Robots.new(contents: "")
        inspect_str = robots.inspect

        assert_includes inspect_str, "Explore::Robots"
      end
    end

    describe "delegated methods from Gort::RobotsTxt" do
      let(:robots_content) do
        <<~ROBOTS
          User-agent: *
          Disallow: /admin/
          Disallow: /private/
          Allow: /public/

          User-agent: Googlebot
          Disallow: /secret/
          Allow: /admin/google-only/

          User-agent: BadBot
          Disallow: /
        ROBOTS
      end

      let(:robots) { Robots.new(contents: robots_content) }

      describe "#allow?" do
        it "returns true for allowed paths" do
          assert robots.allow?("MyBot", "/public/page")
          assert robots.allow?("MyBot", "/")
          assert robots.allow?("MyBot", "/about")
        end

        it "returns false for disallowed paths" do
          refute robots.allow?("MyBot", "/admin/")
          refute robots.allow?("MyBot", "/admin/users")
          refute robots.allow?("MyBot", "/private/data")
        end

        it "respects user agent specific rules" do
          assert robots.allow?("Googlebot", "/admin/google-only/")
          refute robots.allow?("Googlebot", "/secret/")
        end

        it "handles wildcard user agent" do
          assert robots.allow?("*", "/public/page")
          refute robots.allow?("*", "/admin/")
        end

        it "handles paths with query strings" do
          assert robots.allow?("MyBot", "/public/page?query=value")
          refute robots.allow?("MyBot", "/admin/?query=value")
        end

        it "handles BadBot with explicit disallow rule" do
          # BadBot has "Disallow: /" in its section
          refute robots.allow?("BadBot", "/")
          refute robots.allow?("BadBot", "/anything")
          # But /public/ is explicitly allowed in the wildcard section
          # and Gort applies the most specific matching rules
          assert robots.allow?("BadBot", "/public/")
        end
      end

      describe "#disallow?" do
        it "returns true for disallowed paths" do
          assert robots.disallow?("MyBot", "/admin/")
          assert robots.disallow?("MyBot", "/admin/users")
          assert robots.disallow?("MyBot", "/private/data")
        end

        it "returns false for allowed paths" do
          refute robots.disallow?("MyBot", "/public/page")
          refute robots.disallow?("MyBot", "/")
          refute robots.disallow?("MyBot", "/about")
        end

        it "respects user agent specific rules" do
          refute robots.disallow?("Googlebot", "/admin/google-only/")
          assert robots.disallow?("Googlebot", "/secret/")
        end

        it "handles wildcard user agent" do
          refute robots.disallow?("*", "/public/page")
          assert robots.disallow?("*", "/admin/")
        end

        it "handles paths with query strings" do
          refute robots.disallow?("MyBot", "/public/page?query=value")
          assert robots.disallow?("MyBot", "/admin/?query=value")
        end

        it "handles BadBot with explicit disallow rule" do
          # BadBot has "Disallow: /" in its section
          assert robots.disallow?("BadBot", "/")
          assert robots.disallow?("BadBot", "/anything")
          # But /public/ is explicitly allowed in the wildcard section
          refute robots.disallow?("BadBot", "/public/")
        end
      end

      describe "empty robots.txt" do
        let(:empty_robots) { Robots.new(contents: "") }

        it "allows everything when robots.txt is empty" do
          assert empty_robots.allow?("MyBot", "/")
          assert empty_robots.allow?("MyBot", "/any/path")
        end

        it "disallows nothing when robots.txt is empty" do
          refute empty_robots.disallow?("MyBot", "/")
          refute empty_robots.disallow?("MyBot", "/any/path")
        end
      end

      describe "edge cases" do
        it "handles root path" do
          assert robots.allow?("MyBot", "/")
          refute robots.disallow?("MyBot", "/")
        end

        it "handles trailing slashes" do
          refute robots.allow?("MyBot", "/admin/")
          assert robots.disallow?("MyBot", "/admin/")
        end

        it "handles case sensitivity" do
          # robots.txt paths are case-sensitive
          # Only /admin/ (lowercase) is disallowed, so /ADMIN/ and /Admin/ are allowed
          assert robots.allow?("MyBot", "/ADMIN/")
          assert robots.allow?("MyBot", "/Admin/")
          refute robots.allow?("MyBot", "/admin/")
        end
      end
    end
  end
end
