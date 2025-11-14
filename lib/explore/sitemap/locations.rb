# frozen_string_literal: true

module Explore
  module Sitemap
    class Locations
      include Enumerable

      DATA = YAML.load_file(File.join(File.dirname(__FILE__), "../../../data/sitemaps.yml"))

      class << self
        def all
          DATA.map { |source| Source.new(**source.symbolize_keys) }
        end
      end

      attr_reader :sources

      def initialize(sources: Explore::Sitemap::Locations.all)
        @sources = sources
      end

      def each(&)
        sources.each(&)
      end

      def +(other)
        self.class.new(sources: sources + other.sources)
      end

      def find_by_tags(tags)
        tags = Array.wrap(tags).map(&:to_s)
        sources.select { |source| source.tags.any? { |tag| tags.include?(tag) } }
      end
    end
  end
end
