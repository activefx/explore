require "test_helper"

module Explore
  class ResourceTest < Minitest::Test
    def test_initializes_with_a_uri
      uri = "https://example.com/path"
      resource = Resource.new(uri)

      assert_instance_of Addressable::URI, resource.uri
      assert_equal uri, resource.uri.to_s
    end

    def test_initializes_with_a_host
      uri = "https://example.com/path"
      resource = Resource.new(uri)

      assert_instance_of PublicSuffix::Domain, resource.host
      assert_equal "example.com", resource.host.domain
    end
  end
end
