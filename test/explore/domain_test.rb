# frozen_string_literal: true

require "test_helper"

module Explore
  class DomainTest < Minitest::Test
    def setup
      @simple_domain = Explore::Domain.new("example.com")
      @subdomain = Explore::Domain.new("blog.example.com")
      @www_domain = Explore::Domain.new("www.example.com")
      @ww3_domain = Explore::Domain.new("ww3.example.com")
    end

    def test_initialization
      assert_instance_of Explore::Domain, @simple_domain
      assert_instance_of Explore::Domain, @subdomain
    end

    def test_default_options
      assert_equal({ ignore_private: true }, @simple_domain.options)
    end

    def test_custom_options
      domain = Explore::Domain.new("example.com", ignore_private: false)

      assert_equal({ ignore_private: false }, domain.options)
    end

    def test_domain_parsing
      assert_equal "example.com", @simple_domain.to_s
      assert_equal "blog.example.com", @subdomain.to_s
      assert_equal "www.example.com", @www_domain.to_s
    end

    def test_tld
      assert_equal "com", @simple_domain.tld
      assert_equal "com", @subdomain.tld
    end

    def test_sld
      assert_equal "example", @simple_domain.sld
      assert_equal "example", @subdomain.sld
    end

    def test_trd
      assert_nil @simple_domain.trd
      assert_equal "blog", @subdomain.trd
    end

    def test_domain_parts
      assert_equal [nil, "example", "com"], @simple_domain.to_a
      assert_equal %w[blog example com], @subdomain.to_a
    end

    def test_registered_domain
      assert_equal "example.com", @simple_domain.registered_domain
      assert_equal "example.com", @www_domain.registered_domain
      assert_equal "example.com", @subdomain.registered_domain
    end

    def test_www_detection
      assert_nil @simple_domain.www
      assert_equal "www", @www_domain.www
      assert_nil @subdomain.www
      assert_equal "ww3", @ww3_domain.www
    end

    def test_key_generation
      assert_equal "example.com", @simple_domain.key
      assert_equal "example.com", @www_domain.key
      assert_equal "blog.example.com", @subdomain.key
      assert_equal "example.com", @ww3_domain.key
    end

    def test_invalid_domain
      assert_raises(PublicSuffix::DomainInvalid) do
        Explore::Domain.new("invalid")
      end
    end

    def test_method_delegation
      assert_respond_to @simple_domain, :domain
      assert_respond_to @simple_domain, :tld
      assert_respond_to @simple_domain, :sld
    end

    def test_method_missing
      assert_raises(NoMethodError) do
        @simple_domain.nonexistent_method
      end
    end

    def test_respond_to_missing
      assert_respond_to @simple_domain, :tld
      assert_respond_to @simple_domain, :sld
      refute_respond_to @simple_domain, :nonexistent_method
    end
  end
end
