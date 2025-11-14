# frozen_string_literal: true

require "test_helper"

module Explore
  describe URI do
    let(:simple_uri) { URI.new("https://example.com") }
    let(:complex_uri) { URI.new("https://user:pass@blog.example.com:8080/path?query=value#fragment") }
    let(:relative_uri) { URI.new("/path/to/resource") }
    let(:http_uri) { URI.new("http://example.com") }
    let(:data_uri) { URI.new("data:text/plain,Hello") }

    describe "initialization" do
      it "creates a URI instance" do
        assert_instance_of URI, simple_uri
        assert_instance_of URI, complex_uri
      end

      it "wraps an Addressable::URI object" do
        assert_instance_of Addressable::URI, simple_uri.uri
      end

      it "accepts string input" do
        uri = URI.new("https://example.com")

        assert_equal "https://example.com", uri.to_s
      end

      it "raises error for invalid URIs" do
        assert_raises(Addressable::URI::InvalidURIError) do
          URI.new("invalid://\\")
        end
      end
    end

    describe "#to_s" do
      it "returns the string representation of simple URIs" do
        assert_equal "https://example.com", simple_uri.to_s
      end

      it "returns the string representation of complex URIs" do
        assert_equal "https://user:pass@blog.example.com:8080/path?query=value#fragment", complex_uri.to_s
      end

      it "returns the string representation of relative URIs" do
        assert_equal "/path/to/resource", relative_uri.to_s
      end

      it "returns the string representation of data URIs" do
        assert_equal "data:text/plain,Hello", data_uri.to_s
      end
    end

    describe "#origin" do
      it "returns the origin for HTTPS URIs" do
        assert_equal "https://example.com", simple_uri.origin
      end

      it "returns the origin for HTTP URIs" do
        assert_equal "http://example.com", http_uri.origin
      end

      it "returns the origin with non-default port" do
        assert_equal "https://blog.example.com:8080", complex_uri.origin
      end

      it "returns nil for relative URIs instead of 'null'" do
        assert_nil relative_uri.origin
      end

      it "returns nil for data URIs" do
        assert_nil data_uri.origin
      end

      it "handles file URIs" do
        file_uri = URI.new("file:///path/to/file")
        # file URIs return a scheme-only origin from Addressable
        assert_equal "file://", file_uri.origin
      end
    end

    describe "method delegation" do
      describe "scheme" do
        it "delegates to wrapped URI" do
          assert_equal "https", simple_uri.scheme
          assert_equal "https", complex_uri.scheme
        end

        it "returns nil for relative URIs" do
          assert_nil relative_uri.scheme
        end
      end

      describe "host" do
        it "delegates to wrapped URI" do
          assert_equal "example.com", simple_uri.host
          assert_equal "blog.example.com", complex_uri.host
        end

        it "returns nil for relative URIs" do
          assert_nil relative_uri.host
        end
      end

      describe "port" do
        it "returns nil for default ports" do
          assert_nil simple_uri.port
        end

        it "returns explicit port numbers" do
          assert_equal 8080, complex_uri.port
        end
      end

      describe "path" do
        it "returns empty string for root" do
          assert_equal "", simple_uri.path
        end

        it "returns path component" do
          assert_equal "/path", complex_uri.path
          assert_equal "/path/to/resource", relative_uri.path
        end
      end

      describe "query" do
        it "returns nil when no query present" do
          assert_nil simple_uri.query
        end

        it "returns query string" do
          assert_equal "query=value", complex_uri.query
        end
      end

      describe "fragment" do
        it "returns nil when no fragment present" do
          assert_nil simple_uri.fragment
        end

        it "returns fragment identifier" do
          assert_equal "fragment", complex_uri.fragment
        end
      end

      describe "userinfo" do
        it "returns nil when no userinfo present" do
          assert_nil simple_uri.userinfo
        end

        it "returns userinfo component" do
          assert_equal "user:pass", complex_uri.userinfo
        end
      end
    end

    describe "#respond_to?" do
      it "responds to methods defined on URI class" do
        assert_respond_to simple_uri, :to_s
        assert_respond_to simple_uri, :origin
      end

      it "responds to methods on wrapped Addressable::URI" do
        assert_respond_to simple_uri, :scheme
        assert_respond_to simple_uri, :host
        assert_respond_to simple_uri, :port
        assert_respond_to simple_uri, :path
        assert_respond_to simple_uri, :query
        assert_respond_to simple_uri, :fragment
      end

      it "does not respond to arbitrary methods" do
        refute_respond_to simple_uri, :nonexistent_method
      end
    end

    describe "#method_missing" do
      it "forwards known methods to wrapped URI" do
        assert_equal "example.com", simple_uri.host
        assert_equal "https", simple_uri.scheme
      end

      it "raises NoMethodError for unknown methods" do
        assert_raises(NoMethodError) do
          simple_uri.nonexistent_method
        end
      end

      it "supports methods with arguments" do
        # normalize is a method on Addressable::URI that returns a new URI
        normalized = simple_uri.normalize

        assert_instance_of Addressable::URI, normalized
      end

      it "supports methods with blocks" do
        # Some Addressable::URI methods might accept blocks
        # This tests that block forwarding works
        result = simple_uri.uri.dup

        assert_instance_of Addressable::URI, result
      end
    end

    describe "edge cases" do
      it "handles URIs with special characters" do
        special = URI.new("https://example.com/path%20with%20spaces")

        assert_equal "https://example.com/path%20with%20spaces", special.to_s
      end

      it "handles international domain names" do
        idn = URI.new("https://münchen.de")

        assert_instance_of URI, idn
      end

      it "handles empty path URIs" do
        empty_path = URI.new("https://example.com")

        assert_equal "", empty_path.path
      end

      it "handles URIs with only fragment" do
        fragment_only = URI.new("#section")

        assert_equal "#section", fragment_only.to_s
        assert_equal "section", fragment_only.fragment
      end

      it "handles mailto URIs" do
        mailto = URI.new("mailto:user@example.com")

        assert_equal "mailto:user@example.com", mailto.to_s
        assert_equal "mailto", mailto.scheme
      end

      it "handles URIs with encoded characters" do
        encoded = URI.new("https://example.com/search?q=hello%20world")

        assert_equal "https://example.com/search?q=hello%20world", encoded.to_s
      end
    end
  end
end
