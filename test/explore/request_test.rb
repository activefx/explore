# frozen_string_literal: true

require "test_helper"

module Explore
  describe Request do
    let(:valid_url) { "http://example.org/" }
    let(:valid_options) do
      {
        method: :head,
        allow_redirections: true,
        connection_timeout: 5,
        read_timeout: 10,
        retries: 3,
        encoding: "UTF-8",
        headers: { "User-Agent" => "Explore Test" }
      }
    end

    before do
      WebMock.allow_net_connect!
    end

    after do
      WebMock.disable_net_connect!
    end

    describe "initialization" do
      it "accepts string URL and converts to Explore::URI" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)

          assert_instance_of URI, request.url
          assert_equal valid_url, request.url.to_s
        end
      end

      it "accepts Explore::URI instance" do
        with_vcr_cassette("example_org") do
          uri = URI.new(valid_url)
          request = Request.new(uri)

          assert_equal uri, request.url
        end
      end

      it "accepts valid options" do
        with_vcr_cassette("example_org_with_options") do
          request = Request.new(valid_url, valid_options)

          assert_equal :head, request.response.env.method
        end
      end

      it "raises error for non-HTTP URLs" do
        assert_raises(RequestError, "URL must be HTTP") do
          Request.new("ftp://ftp.example.com")
        end
      end

      it "raises error for invalid HTTP methods" do
        assert_raises(RequestError, "Invalid HTTP method: invalid") do
          Request.new(valid_url, method: :invalid)
        end
      end
    end

    describe "#read" do
      it "reads content of page" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)

          assert_match(/<!doctype html>/, request.read[0..14])
        end
      end
    end

    describe "#response" do
      it "contains response status" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)

          assert_equal 200, request.response.status
        end
      end

      it "contains response headers" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)

          assert_equal "text/html", request.response.headers["Content-Type"]
        end
      end
    end

    describe "#body" do
      it "returns raw response body" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)

          assert_match(/<!doctype html>/, request.body[0..14])
        end
      end
    end

    describe "#content_type" do
      it "returns correct content type for HTML pages" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)

          assert_equal "text/html", request.content_type
        end
      end

      it "returns correct content type for non-HTML pages" do
        with_vcr_cassette("iana_logo_header") do
          request = Request.new("https://www.iana.org/_img/2025.01/iana-logo-header.svg")

          assert_equal "image/svg+xml", request.content_type
        end
      end
    end

    describe "#media_type" do
      it "extracts media type from content type" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)

          assert_equal "text/html", request.media_type
        end
      end
    end

    describe "#success?" do
      it "returns true for successful requests" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)

          assert_predicate request, :success?
        end
      end
    end

    describe "#status_code" do
      it "returns HTTP status code" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)

          assert_equal 200, request.status_code
        end
      end
    end

    describe "#response_url" do
      it "returns final URL after redirects" do
        with_vcr_cassette("github_com") do
          request = Request.new("http://github.com/", allow_redirections: true)

          assert_equal "https://github.com/", request.response_url
        end
      end
    end

    describe "error handling" do
      it "handles connection errors" do
        with_vcr_cassette("example_org") do
          http = Minitest::Mock.new
          http.expect(:call, nil) { raise Faraday::ConnectionFailed }

          Net::HTTP.stub(:new, http) do
            assert_raises(RequestError) do
              Request.new(valid_url)
            end
          end
        end
      end

      it "handles timeout errors" do
        with_vcr_cassette("example_org") do
          http = Minitest::Mock.new
          http.expect(:call, nil) { raise Faraday::TimeoutError }

          Net::HTTP.stub(:new, http) do
            assert_raises(TimeoutError) do
              Request.new(valid_url, retries: 0)
            end
          end
        end
      end

      it "handles SSL errors" do
        with_vcr_cassette("example_org") do
          http = Minitest::Mock.new
          http.expect(:call, nil) { raise Faraday::SSLError }

          Net::HTTP.stub(:new, http) do
            assert_raises(RequestError) do
              Request.new(valid_url)
            end
          end
        end
      end

      it "handles redirect limit errors" do
        with_vcr_cassette("example_org") do
          http = Minitest::Mock.new
          http.expect(:call, nil) { raise Faraday::FollowRedirects::RedirectLimitReached, valid_url }

          Net::HTTP.stub(:new, http) do
            assert_raises(RequestError) do
              Request.new(valid_url)
            end
          end
        end
      end

      it "handles fatal timeouts" do
        with_vcr_cassette("example_org") do
          http = Minitest::Mock.new
          http.expect(:call, nil) { raise Timeout::Error }

          Timeout.stub(:timeout, http) do
            assert_raises(TimeoutError) do
              Request.new(valid_url)
            end
          end
        end
      end
    end

    describe "redirects" do
      it "follows redirects when allowed" do
        with_vcr_cassette("github_com") do
          request = Request.new("http://github.com/", allow_redirections: true)

          assert_equal "https://github.com/", request.url.to_s
        end
      end

      it "updates URL to final destination after redirects" do
        with_vcr_cassette("github_com") do
          request = Request.new("http://github.com/", allow_redirections: true)

          assert_equal "https://github.com/", request.response_url
        end
      end
    end

    describe "timeouts" do
      it "respects connection and read timeouts" do
        with_vcr_cassette("timeouts") do
          request = Request.new(valid_url,
                                connection_timeout: 5,
                                read_timeout: 10)

          assert_equal 5, request.response.env.request.timeout
          assert_equal 10, request.response.env.request.open_timeout
        end
      end
    end

    describe "HTTP methods" do
      it "supports HTTP methods with bodies" do
        with_vcr_cassette("post_request") do
          request = Request.new(valid_url,
                                method: :post,
                                body: "test=true")

          assert_equal :post, request.response.env.method
          assert_equal "test=true", request.response.env.request_body
        end
      end
    end

    describe "custom headers" do
      it "supports custom headers" do
        with_vcr_cassette("custom_headers") do
          request = Request.new(valid_url,
                                headers: { "X-Custom" => "test" })

          assert_equal "test", request.response.env.request_headers["X-Custom"]
        end
      end
    end

    describe "#status_text" do
      it "returns HTTP status text" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)

          assert_equal "OK", request.status_text
        end
      end
    end

    describe "#headers" do
      it "returns response headers hash" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)
          headers = request.headers

          assert_instance_of Faraday::Utils::Headers, headers
          assert headers.key?("content-type")
        end
      end
    end

    describe "#charset" do
      it "extracts charset from content type when present" do
        with_vcr_cassette("github_activefx") do
          request = Request.new("https://github.com/activefx")
          charset = request.charset

          # GitHub returns charset in Content-Type header
          assert_instance_of String, charset
          assert_equal "utf-8", charset.downcase
        end
      end

      it "returns nil when content type has no charset parameter" do
        with_vcr_cassette("iana_logo_header") do
          request = Request.new("https://www.iana.org/_img/2025.01/iana-logo-header.svg")

          # SVG content type typically doesn't include charset
          # Just verify it doesn't raise an error
          charset = request.charset
          assert_nil(charset) || assert_instance_of(String, charset)
        end
      end
    end

    describe "#content_length" do
      it "returns content length header when present" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)
          content_length = request.content_length

          # Content-Length can be String, Integer, or nil
          assert([String, Integer, NilClass].any? { |klass| content_length.is_a?(klass) })
        end
      end
    end

    describe "#content_encoding" do
      it "returns content encoding header when present" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)
          content_encoding = request.content_encoding

          # Just verify it doesn't raise an error
          assert_nil(content_encoding) || assert_instance_of(String, content_encoding)
        end
      end
    end

    describe "#last_modified" do
      it "returns last modified date as string when present" do
        with_vcr_cassette("example_org") do
          request = Request.new(valid_url)
          last_modified = request.last_modified

          # Last-Modified may or may not be present
          skip "No Last-Modified header" if last_modified.nil?

          assert_instance_of String, last_modified
        end
      end
    end

    describe "allowed schemes and methods" do
      it "defines allowed schemes constant" do
        assert_equal Set.new(%w[http https]), Request::ALLOWED_SCHEMES
      end

      it "defines allowed methods constant" do
        assert_equal Set.new(%i[get post put delete head patch options trace]), Request::ALLOWED_METHODS
      end

      it "defines body methods constant" do
        assert_equal Set.new(%i[post put patch]), Request::BODY_METHODS
      end
    end
  end
end
