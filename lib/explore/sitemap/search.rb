# frozen_string_literal: true

module Explore
  module Sitemap
    class Search
      # Similar to a HEAD request, as it does not download the body.
      # Used instead of a HEAD request since some sites respond with
      # a 400 level error even when a sitemap is present.
      DEFAULT_OPTIONS = {
        method: :get,
        allow_redirections: true,
        connection_timeout: 5,
        read_timeout: 10,
        retries: 0,
        faraday_options: {
          redirect: {
            limit: 1
          }
        },
        on_data: proc { |_chunk, _overall_received_bytes, env| throw :abort, Faraday::Response.new(env) }
      }.freeze

      attr_reader :sources

      def initialize(sources, crawl_delay: 0.1, strategy: :first)
        @sources = sources
        @crawl_delay = validate_crawl_delay(crawl_delay)
        @strategy = strategy == :first ? :first : :all
      end

      # :pending,
      # :in_progress,
      # :completed,
      # :failed,
      # :retrying

      # :path,
      # :origin,
      # :tags,
      # :content_types,
      # :status,
      # :errors,
      # :response_url,
      # :status_code,
      # :last_modified,
      # :content_type,
      # :content_encoding

      # TODO
      # - add response[:etag]
      # - use #media_type instead of #content_type
      # - use #charset if #content_encoding is nil

      def run
        sources.each_with_index do |source, _index|
          source.status = :in_progress
          begin
            request = Explore::Request.new(source.url, **DEFAULT_OPTIONS)
            if request.success?
              source.status = :completed
              source.response_url = request.url
              source.status_code = request.status_code
              source.last_modified = request.last_modified
              source.content_type = request.content_type
              source.content_encoding = request.content_encoding
            else
              source.status = :failed
              source.status_code = request.status_code
              source.errors << request.status_text
            end
            break if request.success? && @strategy == :first
          rescue Explore::TimeoutError, Explore::RequestError => e
            source.status = :failed
            source.status_code = request.status_code
            source.errors << e.message
          end
          sleep @crawl_delay # dont flood the site with sitemap checks
        end
        sources
      end

      private

      def validate_crawl_delay(crawl_delay)
        raise ArgumentError, "Crawl delay must be between 0 and 60 seconds" unless (0..60).include?(crawl_delay)

        crawl_delay
      end
    end
  end
end
