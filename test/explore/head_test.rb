# frozen_string_literal: true

require "test_helper"

module Explore
  describe Head do
    let(:valid_url) { "https://example.org" }
    let(:valid_uri) { Explore::URI.new(valid_url) }

    describe "initialization" do
      it "initializes with string url" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          assert_instance_of Head, head
          assert_instance_of Explore::Request, head.request
        end
      end

      it "initializes with explore uri instance" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_uri)

          assert_instance_of Head, head
          assert_instance_of Explore::Request, head.request
        end
      end

      it "initializes with custom options" do
        custom_options = {
          connection_timeout: 10,
          read_timeout: 20,
          retries: 5
        }

        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url, custom_options)

          assert_instance_of Head, head
          assert_instance_of Explore::Request, head.request
        end
      end

      it "has frozen default options" do
        assert_predicate Head::DEFAULT_OPTIONS, :frozen?
        assert_raises(FrozenError) do
          Head::DEFAULT_OPTIONS[:method] = :get
        end
      end

      it "merges custom options with defaults" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url, retries: 10)

          assert_equal :head, head.request.response.env.method
        end
      end
    end

    describe "success checking" do
      it "returns success for valid url" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          assert_predicate head, :success?
          assert_empty head.errors
        end
      end

      it "returns true for 2xx status codes" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          assert_predicate head, :success?
          assert_equal 200, head.status_code
        end
      end
    end

    describe "uri handling" do
      it "returns final uri after request" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          assert_instance_of Explore::URI, head.uri
          assert_match %r{^https://example\.org/?$}, head.uri.to_s
        end
      end

      it "returns final uri after redirect" do
        with_vcr_cassette("head_github_redirect") do
          head = Head.new("http://github.com/")

          assert_equal "https://github.com/", head.uri.to_s
        end
      end

      it "returns nil when request fails" do
        with_vcr_cassette("non_existent_head_request") do
          head = Head.new("https://non-existent-domain-12345.com")

          assert_nil head.uri
        end
      end
    end

    describe "status information" do
      it "returns http status code" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          assert_equal 200, head.status_code
        end
      end

      it "returns status reason phrase" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          assert_equal "OK", head.status_text
        end
      end
    end

    describe "headers" do
      it "returns response headers" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          assert_instance_of Faraday::Utils::Headers, head.headers
          refute_empty head.headers
        end
      end

      it "returns content type header" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          assert_equal "text/html", head.content_type
        end
      end

      it "responds to content encoding" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          assert_respond_to head, :content_encoding
        end
      end

      it "returns parsed last modified date" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          refute_nil head.last_modified
          assert_instance_of String, head.last_modified
        end
      end

      it "returns nil when last modified not present" do
        with_vcr_cassette("head_no_last_modified") do
          head = Head.new("http://example.com/no-last-modified")

          assert_nil head.last_modified
        end
      end
    end

    describe "error handling" do
      it "handles non existent urls" do
        with_vcr_cassette("non_existent_head_request") do
          head = Head.new("https://non-existent-domain-12345.com")

          refute_predicate head, :success?
          refute_empty head.errors
          assert_nil head.uri
          assert_nil head.status_code
        end
      end

      it "handles timeout errors" do
        Explore::Request.stub :new, ->(*_args) { raise Explore::TimeoutError, "Request timed out" } do
          head = Head.new(valid_url)

          refute_predicate head, :success?
          refute_empty head.errors
          assert_match(/timed out/i, head.errors.first)
        end
      end

      it "handles connection errors" do
        Explore::Request.stub :new, ->(*_args) { raise Explore::RequestError, "Connection failed" } do
          head = Head.new(valid_url)

          refute_predicate head, :success?
          refute_empty head.errors
          assert_match(/connection/i, head.errors.first)
        end
      end
    end

    describe "delegation" do
      it "delegates response to request" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          assert_respond_to head, :response
          assert_instance_of Faraday::Response, head.response
        end
      end

      it "returns nil for delegated methods when request fails" do
        with_vcr_cassette("non_existent_head_request") do
          head = Head.new("https://non-existent-domain-12345.com")

          assert_nil head.response
          assert_nil head.success?
          assert_nil head.status_code
          assert_nil head.status_text
          assert_nil head.headers
          assert_nil head.content_type
          assert_nil head.content_encoding
          assert_nil head.last_modified
        end
      end
    end

    describe "request object" do
      it "returns request object" do
        with_vcr_cassette("head_example_org") do
          head = Head.new(valid_url)

          assert_instance_of Explore::Request, head.request
        end
      end

      it "has nil request when initialization fails" do
        with_vcr_cassette("non_existent_head_request") do
          head = Head.new("https://non-existent-domain-12345.com")

          assert_nil head.request
        end
      end
    end

    describe "redirects" do
      it "follows redirects by default" do
        with_vcr_cassette("head_github_redirect") do
          head = Head.new("http://github.com/")

          assert_predicate head, :success?
          assert_equal "https://github.com/", head.uri.to_s
        end
      end

      it "respects redirect limit options" do
        with_vcr_cassette("head_too_many_redirects") do
          head = Head.new("http://github.com/", faraday_options: { redirect: { limit: 0 } })

          assert_instance_of Head, head
        end
      end
    end
  end
end
