# frozen_string_literal: true

require "test_helper"

module Explore
  class URITest < Minitest::Test
    def setup
      @simple_uri = Explore::URI.new("https://example.com")
      @complex_uri = Explore::URI.new("https://user:pass@blog.example.com:8080/path?query=value#fragment")
    end

    def test_initialization
      assert_instance_of Explore::URI, @simple_uri
      assert_instance_of Explore::URI, @complex_uri
    end

    def test_scheme
      assert_equal "https", @simple_uri.scheme
      assert_equal "https", @complex_uri.scheme
    end

    def test_host
      assert_equal "example.com", @simple_uri.host
      assert_equal "blog.example.com", @complex_uri.host
    end

    def test_port
      assert_nil @simple_uri.port
      assert_equal 8080, @complex_uri.port
    end

    def test_path
      assert_equal "", @simple_uri.path
      assert_equal "/path", @complex_uri.path
    end

    def test_query
      assert_nil @simple_uri.query
      assert_equal "query=value", @complex_uri.query
    end

    def test_fragment
      assert_nil @simple_uri.fragment
      assert_equal "fragment", @complex_uri.fragment
    end

    def test_userinfo
      assert_nil @simple_uri.userinfo
      assert_equal "user:pass", @complex_uri.userinfo
    end

    def test_method_delegation
      assert_respond_to @simple_uri, :scheme
      assert_respond_to @simple_uri, :host
      assert_respond_to @simple_uri, :port
    end

    def test_invalid_uri
      assert_raises(Addressable::URI::InvalidURIError) do
        Explore::URI.new("invalid://\\")
      end
    end

    def test_to_s
      assert_equal "https://example.com", @simple_uri.to_s
      assert_equal "https://user:pass@blog.example.com:8080/path?query=value#fragment", @complex_uri.to_s
    end
  end
end
