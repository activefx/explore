# frozen_string_literal: true

require "test_helper"

module Explore
  describe Domain do
    let(:simple_domain) { Domain.new("example.com") }
    let(:subdomain) { Domain.new("blog.example.com") }
    let(:www_domain) { Domain.new("www.example.com") }
    let(:ww3_domain) { Domain.new("ww3.example.com") }

    describe "initialization" do
      it "creates domain instances" do
        assert_instance_of Domain, simple_domain
        assert_instance_of Domain, subdomain
      end

      it "uses default options" do
        assert_equal({ ignore_private: true }, simple_domain.options)
      end

      it "accepts custom options" do
        domain = Domain.new("example.com", ignore_private: false)

        assert_equal({ ignore_private: false }, domain.options)
      end

      it "raises on invalid domain" do
        assert_raises(PublicSuffix::DomainInvalid) do
          Domain.new("invalid")
        end
      end
    end

    describe "string representation" do
      it "returns full domain with to_s" do
        assert_equal "example.com", simple_domain.to_s
        assert_equal "blog.example.com", subdomain.to_s
        assert_equal "www.example.com", www_domain.to_s
      end

      it "returns domain parts as array" do
        assert_equal [nil, "example", "com"], simple_domain.to_a
        assert_equal %w[blog example com], subdomain.to_a
      end
    end

    describe "domain components" do
      it "extracts TLD" do
        assert_equal "com", simple_domain.tld
        assert_equal "com", subdomain.tld
      end

      it "extracts SLD" do
        assert_equal "example", simple_domain.sld
        assert_equal "example", subdomain.sld
      end

      it "extracts TRD" do
        assert_nil simple_domain.trd
        assert_equal "blog", subdomain.trd
      end

      it "extracts registered domain" do
        assert_equal "example.com", simple_domain.registered_domain
        assert_equal "example.com", www_domain.registered_domain
        assert_equal "example.com", subdomain.registered_domain
      end
    end

    describe "www prefix handling" do
      it "detects standard www" do
        assert_equal "www", www_domain.www
      end

      it "detects www variants" do
        assert_equal "ww3", ww3_domain.www
      end

      it "returns nil for non-www domains" do
        assert_nil simple_domain.www
        assert_nil subdomain.www
      end
    end

    describe "key generation" do
      it "removes www prefix" do
        assert_equal "example.com", www_domain.key
      end

      it "removes www variants" do
        assert_equal "example.com", ww3_domain.key
      end

      it "preserves non-www domains" do
        assert_equal "example.com", simple_domain.key
        assert_equal "blog.example.com", subdomain.key
      end
    end

    describe "method delegation" do
      it "delegates to public suffix domain object" do
        assert_respond_to simple_domain, :domain
        assert_respond_to simple_domain, :tld
        assert_respond_to simple_domain, :sld
      end

      it "raises on unknown methods" do
        assert_raises(NoMethodError) do
          simple_domain.nonexistent_method
        end
      end

      it "checks delegation in respond_to_missing" do
        assert_respond_to simple_domain, :tld
        assert_respond_to simple_domain, :sld
        refute_respond_to simple_domain, :nonexistent_method
      end
    end
  end
end
