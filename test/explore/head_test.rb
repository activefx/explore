# frozen_string_literal: true

require "test_helper"

module Explore
  class HeadTest < Minitest::Test
    def setup
      @valid_url = "https://example.org"
    end

    def test_handles_non_existent_url
      non_existent_url = "https://non-existent-domain-12345.com"

      with_vcr_cassette("non_existent_head_request") do
        head = Head.new(non_existent_url)

        refute_predicate head, :success?
        refute_empty head.errors
        assert_equal "https://non-existent-domain-12345.com", head.url
        assert_equal 0, head.status_code # Faraday returns 0 for connection failures
      end
    end

    def test_default_options_are_frozen
      assert_predicate Head::DEFAULT_OPTIONS, :frozen?
      assert_raises(FrozenError) do
        Head::DEFAULT_OPTIONS[:method] = :get
      end
    end
  end
end
