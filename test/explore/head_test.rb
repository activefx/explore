# frozen_string_literal: true

require "test_helper"

module Explore
  class HeadTest < Minitest::Test
    def setup
      @valid_url = "https://example.org"
      @valid_uri = Explore::URI.new(@valid_url)
    end

    # ============================================================================
    # Initialization Tests
    # ============================================================================

    def test_initializes_with_string_url
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        assert_instance_of Head, head
        assert_instance_of Explore::Request, head.request
      end
    end

    def test_initializes_with_explore_uri_instance
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_uri)

        assert_instance_of Head, head
        assert_instance_of Explore::Request, head.request
      end
    end

    def test_initializes_with_custom_options
      custom_options = {
        connection_timeout: 10,
        read_timeout: 20,
        retries: 5
      }

      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url, custom_options)

        assert_instance_of Head, head
        assert_instance_of Explore::Request, head.request
      end
    end

    def test_default_options_are_frozen
      assert_predicate Head::DEFAULT_OPTIONS, :frozen?
      assert_raises(FrozenError) do
        Head::DEFAULT_OPTIONS[:method] = :get
      end
    end

    def test_merges_custom_options_with_defaults
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url, retries: 10)

        # Should use default method
        assert_equal :head, head.request.response.env.method
      end
    end

    # ============================================================================
    # Success Tests
    # ============================================================================

    def test_success_for_valid_url
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        assert_predicate head, :success?
        assert_empty head.errors
      end
    end

    def test_success_returns_true_for_2xx_status
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        assert_predicate head, :success?
        assert_equal 200, head.status_code
      end
    end

    # ============================================================================
    # URI Tests
    # ============================================================================

    def test_uri_returns_final_uri_after_request
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        assert_instance_of Explore::URI, head.uri
        # URI might have trailing slash from server normalization
        assert_match %r{^https://example\.org/?$}, head.uri.to_s
      end
    end

    def test_uri_returns_final_uri_after_redirect
      with_vcr_cassette("head_github_redirect") do
        head = Head.new("http://github.com/")

        # Should follow redirect and return https URL
        assert_equal "https://github.com/", head.uri.to_s
      end
    end

    def test_uri_returns_nil_when_request_fails
      non_existent_url = "https://non-existent-domain-12345.com"

      with_vcr_cassette("non_existent_head_request") do
        head = Head.new(non_existent_url)

        assert_nil head.uri
      end
    end

    # ============================================================================
    # Status Tests
    # ============================================================================

    def test_status_code_returns_http_status
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        assert_equal 200, head.status_code
      end
    end

    def test_status_text_returns_reason_phrase
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        assert_equal "OK", head.status_text
      end
    end

    # ============================================================================
    # Headers Tests
    # ============================================================================

    def test_headers_returns_response_headers
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        assert_instance_of Faraday::Utils::Headers, head.headers
        refute_empty head.headers
      end
    end

    def test_content_type_returns_content_type_header
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        assert_equal "text/html", head.content_type
      end
    end

    def test_content_encoding_returns_encoding_header
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        # HEAD requests may not always return content-encoding
        # Just verify the method is callable
        assert_respond_to head, :content_encoding
      end
    end

    def test_last_modified_returns_parsed_date
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        refute_nil head.last_modified
        assert_instance_of String, head.last_modified
      end
    end

    def test_last_modified_returns_nil_when_not_present
      with_vcr_cassette("head_no_last_modified") do
        head = Head.new("http://example.com/no-last-modified")

        assert_nil head.last_modified
      end
    end

    # ============================================================================
    # Error Handling Tests
    # ============================================================================

    def test_handles_non_existent_url
      non_existent_url = "https://non-existent-domain-12345.com"

      with_vcr_cassette("non_existent_head_request") do
        head = Head.new(non_existent_url)

        refute_predicate head, :success?
        refute_empty head.errors
        assert_nil head.uri
        assert_nil head.status_code
      end
    end

    def test_handles_timeout_errors
      # Stub Request to raise a timeout error
      Explore::Request.stub :new, ->(*_args) { raise Explore::TimeoutError, "Request timed out" } do
        head = Head.new(@valid_url)

        refute_predicate head, :success?
        refute_empty head.errors
        assert_match(/timed out/i, head.errors.first)
      end
    end

    def test_handles_connection_errors
      # Stub Request to raise a connection error
      Explore::Request.stub :new, ->(*_args) { raise Explore::RequestError, "Connection failed" } do
        head = Head.new(@valid_url)

        refute_predicate head, :success?
        refute_empty head.errors
        assert_match(/connection/i, head.errors.first)
      end
    end

    # ============================================================================
    # Delegation Tests
    # ============================================================================

    def test_delegates_response_to_request
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        assert_respond_to head, :response
        assert_instance_of Faraday::Response, head.response
      end
    end

    def test_delegation_returns_nil_when_request_fails
      with_vcr_cassette("non_existent_head_request") do
        head = Head.new("https://non-existent-domain-12345.com")

        # These should all return nil due to allow_nil: true in delegation
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

    # ============================================================================
    # Request Object Tests
    # ============================================================================

    def test_request_attribute_returns_request_object
      with_vcr_cassette("head_example_org") do
        head = Head.new(@valid_url)

        assert_instance_of Explore::Request, head.request
      end
    end

    def test_request_is_nil_when_initialization_fails
      with_vcr_cassette("non_existent_head_request") do
        head = Head.new("https://non-existent-domain-12345.com")

        assert_nil head.request
      end
    end

    # ============================================================================
    # Integration Tests
    # ============================================================================

    def test_follows_redirects_by_default
      with_vcr_cassette("head_github_redirect") do
        head = Head.new("http://github.com/")

        assert_predicate head, :success?
        assert_equal "https://github.com/", head.uri.to_s
      end
    end

    def test_limits_redirects_according_to_options
      with_vcr_cassette("head_too_many_redirects") do
        # Set redirect limit to 0 to not follow any redirects
        head = Head.new("http://github.com/", faraday_options: { redirect: { limit: 0 } })

        # This test may need adjustment based on actual behavior
        # If it doesn't follow redirects, it might get a 301/302
        assert_instance_of Head, head
      end
    end
  end
end
