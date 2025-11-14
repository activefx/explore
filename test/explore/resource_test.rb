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
  end
end
