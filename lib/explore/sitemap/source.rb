# frozen_string_literal: true

module Explore
  module Sitemap
    # Source represents a single sitemap location with its metadata,
    # status, and response information.
    class Source
      STATUS = %i[
        pending
        in_progress
        completed
        failed
        retrying
      ].freeze

      attr_accessor :status, :errors, :response_url, :status_code, :last_modified, :content_type, :content_encoding
      attr_reader :path, :origin, :tags, :content_types

      # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
      def initialize(
        path:,
        origin: nil,
        tags: [],
        content_types: [],
        status: :pending,
        errors: [],
        response_url: nil,
        status_code: nil,
        last_modified: nil,
        content_type: nil,
        content_encoding: nil
      )
        @path = path
        @origin = origin
        @tags = tags
        @content_types = content_types
        @status = status
        @errors = errors
        @response_url = response_url
        @status_code = status_code
        @last_modified = last_modified
        @content_type = content_type
        @content_encoding = content_encoding
      end
      # rubocop:enable Metrics/ParameterLists, Metrics/MethodLength

      def url(origin: @origin)
        Addressable::URI.join(origin, path).to_s
      end

      def redirected?
        return false if url.nil?

        Explore::URI.parse(url).path != path
      end

      def expected_content_type?
        return true if content_types.empty?

        content_types.include?(content_type)
      end
    end
  end
end
