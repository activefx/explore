# frozen_string_literal: true

require "test_helper"

module Explore
  class ResourceTest < Minitest::Test
    def setup
      @simple_resource = Explore::Resource.new("https://example.com")
      @complex_resource = Explore::Resource.new("https://blog.example.com/path?query=value")
    end

    def test_initialization
      assert_instance_of Explore::Resource, @simple_resource
      assert_instance_of Explore::Resource, @complex_resource
    end

    def test_uri_initialization
      assert_instance_of Explore::URI, @simple_resource.uri
      assert_instance_of Explore::URI, @complex_resource.uri
    end

    def test_domain_initialization
      assert_instance_of Explore::Domain, @simple_resource.domain
      assert_instance_of Explore::Domain, @complex_resource.domain
    end

    def test_uri_parsing
      assert_equal "https://example.com", @simple_resource.uri.to_s
      assert_equal "https://blog.example.com/path?query=value", @complex_resource.uri.to_s
    end

    def test_domain_parsing
      assert_equal "example.com", @simple_resource.domain.to_s
      assert_equal "blog.example.com", @complex_resource.domain.to_s
    end

    def test_invalid_resource
      assert_raises(Addressable::URI::InvalidURIError) do
        Explore::Resource.new("invalid://\\")
      end
    end

    def test_domain_default_options
      resource = Explore::Resource.new("https://example.com")

      assert resource.domain.options[:ignore_private]
    end

    def test_domain_custom_options
      resource = Explore::Resource.new("https://example.com", domain: { ignore_private: false })

      refute resource.domain.options[:ignore_private]
    end

    def test_domain_options_override
      # Test that custom options override defaults
      resource = Explore::Resource.new("https://example.com", domain: { ignore_private: false })

      assert_equal({ ignore_private: false }, resource.domain.options)
    end

    def test_head_with_custom_options
      VCR.use_cassette("head_example_org") do
        resource = Explore::Resource.new("https://example.org", head: { retries: 5, connection_timeout: 15 })
        head = resource.head

        assert_instance_of Explore::Head, head
        assert_predicate head, :success?
      end
    end

    def test_head_options_passed_through
      VCR.use_cassette("head_example_org") do
        resource = Explore::Resource.new("https://example.org", head: { retries: 10 })
        head = resource.head

        # The request object should have received the custom retries option
        assert_equal 10, head.request.instance_variable_get(:@retries)
      end
    end

    def test_head_default_behavior_without_options
      VCR.use_cassette("head_example_org") do
        resource = Explore::Resource.new("https://example.org")
        head = resource.head

        # Should use Head's default retries (2)
        assert_equal 2, head.request.instance_variable_get(:@retries)
      end
    end

    def test_robots_with_custom_options
      resource = Explore::Resource.new("https://example.com", robots: { connection_timeout: 20, retries: 7 })

      # Mock the Request to verify options are passed through
      mock_request = Minitest::Mock.new
      mock_request.expect :body, "User-agent: *\nDisallow: /private/"

      Explore::Request.stub :new, lambda { |_url, **opts|
        assert_equal 20, opts[:connection_timeout]
        assert_equal 7, opts[:retries]
        mock_request
      } do
        robots = resource.robots

        assert_instance_of Explore::Robots, robots
        assert_predicate robots, :success?
      end

      mock_request.verify
    end

    def test_robots_default_behavior_without_options
      resource = Explore::Resource.new("https://example.com")

      # Mock the Request to verify default options are used
      mock_request = Minitest::Mock.new
      mock_request.expect :body, "User-agent: *\nDisallow: /"

      Explore::Request.stub :new, lambda { |_url, **opts|
        # Should use Robots' default retries (2)
        assert_equal 2, opts[:retries]
        # Should use Robots' default connection_timeout (5)
        assert_equal 5, opts[:connection_timeout]
        mock_request
      } do
        robots = resource.robots

        assert_instance_of Explore::Robots, robots
      end

      mock_request.verify
    end

    def test_robots_caching
      resource = Explore::Resource.new("https://example.com")

      # Mock the Request - should only be called once due to caching
      mock_request = Minitest::Mock.new
      mock_request.expect :body, "User-agent: *\nDisallow: /"

      Explore::Request.stub :new, lambda { |_url, **_opts|
        mock_request
      } do
        robots1 = resource.robots
        robots2 = resource.robots

        # Should return the same cached object
        assert_same robots1, robots2
      end

      mock_request.verify
    end

    def test_reset_clears_robots_cache
      resource = Explore::Resource.new("https://example.com")

      call_count = 0

      Explore::Request.stub :new, lambda { |_url, **_opts|
        call_count += 1
        mock = Minitest::Mock.new
        mock.expect :body, "User-agent: *\nDisallow: /"
        mock
      } do
        robots1 = resource.robots
        resource.reset!
        robots2 = resource.robots

        # Should be different objects after reset
        refute_same robots1, robots2
        # Should have created two separate Request objects
        assert_equal 2, call_count
      end
    end
  end
end
