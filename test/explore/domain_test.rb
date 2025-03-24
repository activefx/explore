require "test_helper"

class Explore::DomainTest < Minitest::Test
  def setup
    @simple_domain = Explore::Domain.new("example.com")
    @subdomain = Explore::Domain.new("blog.example.com")
  end

  def test_initialization
    assert_instance_of Explore::Domain, @simple_domain
    assert_instance_of Explore::Domain, @subdomain
  end

  def test_domain_parsing
    assert_equal "example.com", @simple_domain.to_s
    assert_equal "blog.example.com", @subdomain.to_s
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
    assert_equal ["blog", "example", "com"], @subdomain.to_a
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

  def test_options_handling
    domain = Explore::Domain.new("example.com", ignore_private: false)
    assert_equal({ ignore_private: false }, domain.options)
  end
end
