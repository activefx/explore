require "test_helper"

module Explore
  class RequestTest < Minitest::Test
    def setup
      WebMock.allow_net_connect!
      @valid_url = "http://example.org/"
      @valid_options = {
        method: :head,
        allow_redirections: true,
        connection_timeout: 5,
        read_timeout: 10,
        retries: 3,
        encoding: "UTF-8",
        headers: { "User-Agent" => "Explore Test" }
      }
    end

    def teardown
      WebMock.disable_net_connect!
    end

    def test_accepts_string_url_and_converts_to_explore_uri
      with_vcr_cassette("example_org") do
        request = Explore::Request.new(@valid_url)
        assert_instance_of Explore::URI, request.url
        assert_equal @valid_url, request.url.to_s
      end
    end

    def test_accepts_explore_uri_instance
      with_vcr_cassette("example_org") do
        uri = Explore::URI.new(@valid_url)
        request = Explore::Request.new(uri)
        assert_equal uri, request.url
      end
    end

    def test_accepts_valid_options
      with_vcr_cassette("example_org_with_options") do
        request = Explore::Request.new(@valid_url, @valid_options)
        assert_equal :head, request.response.env.method
      end
    end

    def test_raises_error_for_non_http_urls
      assert_raises(Explore::RequestError, "URL must be HTTP") do
        Explore::Request.new("ftp://ftp.example.com")
      end
    end

    def test_raises_error_for_invalid_http_methods
      assert_raises(Explore::RequestError, "Invalid HTTP method: invalid") do
        Explore::Request.new(@valid_url, method: :invalid)
      end
    end

    def test_reads_content_of_page
      with_vcr_cassette("example_org") do
        request = Explore::Request.new(@valid_url)
        assert_match(/<!doctype html>/, request.read[0..14])
      end
    end

    def test_contains_response_status
      with_vcr_cassette("example_org") do
        request = Explore::Request.new(@valid_url)
        assert_equal 200, request.response.status
      end
    end

    def test_contains_response_headers
      with_vcr_cassette("example_org") do
        request = Explore::Request.new(@valid_url)
        assert_equal "text/html", request.response.headers["Content-Type"]
      end
    end

    def test_returns_correct_content_type_for_html_pages
      with_vcr_cassette("example_org") do
        request = Explore::Request.new(@valid_url)
        assert_equal "text/html", request.content_type
      end
    end

    def test_returns_correct_content_type_for_non_html_pages
      with_vcr_cassette("iana_logo_header") do
        request = Explore::Request.new("https://www.iana.org/_img/2025.01/iana-logo-header.svg")
        assert_equal "image/svg+xml", request.content_type
      end
    end

    def test_handles_connection_errors
      with_vcr_cassette("example_org") do
        http = Minitest::Mock.new
        http.expect(:call, nil) { raise Faraday::ConnectionFailed }

        Net::HTTP.stub(:new, http) do
          assert_raises(Explore::RequestError) do
            Explore::Request.new(@valid_url)
          end
        end
      end
    end

    def test_handles_timeout_errors
      with_vcr_cassette("example_org") do
        http = Minitest::Mock.new
        http.expect(:call, nil) { raise Faraday::TimeoutError }

        Net::HTTP.stub(:new, http) do
          assert_raises(Explore::TimeoutError) do
            Explore::Request.new(@valid_url, retries: 0)
          end
        end
      end
    end

    def test_handles_ssl_errors
      with_vcr_cassette("example_org") do
        http = Minitest::Mock.new
        http.expect(:call, nil) { raise Faraday::SSLError }

        Net::HTTP.stub(:new, http) do
          assert_raises(Explore::RequestError) do
            Explore::Request.new(@valid_url)
          end
        end
      end
    end

    def test_handles_redirect_limit_errors
      with_vcr_cassette("example_org") do
        http = Minitest::Mock.new
        http.expect(:call, nil) { raise Faraday::FollowRedirects::RedirectLimitReached, @valid_url }

        Net::HTTP.stub(:new, http) do
          assert_raises(Explore::RequestError) do
            Explore::Request.new(@valid_url)
          end
        end
      end
    end

    def test_handles_fatal_timeouts
      with_vcr_cassette("example_org") do
        http = Minitest::Mock.new
        http.expect(:call, nil) { raise Timeout::Error }

        Timeout.stub(:timeout, http) do
          assert_raises(Explore::TimeoutError) do
            Explore::Request.new(@valid_url)
          end
        end
      end
    end

    def test_follows_redirects_when_allowed
      with_vcr_cassette("github_com") do
        request = Explore::Request.new("http://github.com/",
          allow_redirections: true)
        assert_equal "https://github.com/", request.url.to_s
      end
    end

    def test_respects_connection_and_read_timeouts
      with_vcr_cassette("timeouts") do
        request = Explore::Request.new(@valid_url,
          connection_timeout: 5,
          read_timeout: 10)
        assert_equal 5, request.response.env.request.timeout
        assert_equal 10, request.response.env.request.open_timeout
      end
    end

    def test_supports_http_methods_with_bodies
      with_vcr_cassette("post_request") do
        request = Explore::Request.new(@valid_url,
          method: :post,
          body: "test=true")
        assert_equal :post, request.response.env.method
        assert_equal "test=true", request.response.env.request_body
      end
    end

    def test_supports_custom_headers
      with_vcr_cassette("custom_headers") do
        request = Explore::Request.new(@valid_url,
          headers: { "X-Custom" => "test" })
        assert_equal "test", request.response.env.request_headers["X-Custom"]
      end
    end
  end
end
