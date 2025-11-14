# frozen_string_literal: true

module Explore
  # Represents a web resource identified by a URI
  #
  # This is the main class returned by Explore.new() that provides access to
  # various exploration methods like HEAD requests, robots.txt parsing, etc.
  class Resource
    # @return [Explore::URI] The parsed URI for this resource
    attr_reader :uri

    # @return [Explore::Domain] The domain information for this resource
    attr_reader :domain

    # Initialize a new Resource
    #
    # @param input [String, Explore::URI] The URI to explore
    # @param options [Hash] Options for resource exploration (reserved for future use)
    def initialize(input, **options)
      @uri = input.is_a?(Explore::URI) ? input : Explore::URI.new(input)
      @domain = Explore::Domain.new(@uri.host, ignore_private: true)
      @head = nil
      @robots = nil
      @options = options
    end

    # Perform a HEAD request to the URI and return the response information.
    # Results are cached - subsequent calls return the same Head object.
    #
    # @return [Explore::Head] The HEAD request response
    def head
      @head ||= Explore::Head.new(@uri)
    end

    # Check if a HEAD request has been made and was successful
    #
    # @return [Boolean] true if HEAD request was made and succeeded
    def head?
      !!@head && @head.success?
    end

    # Get the robots.txt URL for this resource
    # Uses the final URL from HEAD request if available, otherwise uses the original URI
    #
    # @return [String] The robots.txt URL
    def robots_txt_url
      if head?
        "#{head.uri.scheme}://#{head.uri.host}/robots.txt"
      else
        "#{@uri.scheme}://#{@uri.host}/robots.txt"
      end
    end

    # Parse and return the robots.txt file for this resource
    #
    # @return [Explore::Robots] The parsed robots.txt
    def robots
      @robots ||= Explore::Robots.new(uri: robots_txt_url)
    end

    # Get sitemap locations from robots.txt
    #
    # @return [Explore::Sitemap::Locations] Sitemap locations from robots.txt
    def robots_sitemap_locations
      sources = robots.sitemaps.map do |sitemap|
        sitemap_uri = Explore::URI.new(sitemap)
        Explore::Sitemap::Source.new(
          path: sitemap_uri.path,
          origin: sitemap_uri.origin,
          tags: ["robots"]
        )
      end
      Explore::Sitemap::Locations.new(sources: sources)
    end

    # def meta_sitemap_locations
    #   browser = Explore::Browser.new(uri)
    #   browser.meta_tags.sitemap
    # end

    # def manual_sitemap(depth = 0)
    #   # TODO: Get all internal links from the homepage
    # end

    # Find and retrieve sitemaps for this resource
    #
    # With the tag :robots, this method will return the sitemap sources from the robots.txt file.
    # To check additional sources, pass an array of tags. Common tags include :robots, :common, :extended,
    # :news, and :content. For a full list, see Explore::Sitemap::Locations::DATA.
    # To check all data file sources, use the tag :all. Be sure to include the :robots tag to check
    # the sitemap sources from the robots.txt file if needed when using the :all tag.
    #
    # @param sources [Explore::Sitemap::Locations] Sitemap locations to search
    # @param crawl_delay [Float] Delay between requests
    # @param strategy [Symbol] Search strategy (:all, etc)
    # @param tags [Array<Symbol>] Tags to filter sources by
    # @return [Array] Found sitemaps
    def sitemaps(sources: sitemap_locations, crawl_delay: 0.1, strategy: :all, tags: [:robots])
      sources = sources.find_by_tags(tags)
      search = Explore::Sitemap::Search.new(sources, crawl_delay: crawl_delay, strategy: strategy)
      search.run
    end

    # Reset cached data (HEAD request, robots.txt, etc)
    #
    # @return [nil]
    def reset!
      @head = nil
      @robots = nil
    end

    private

    def sitemap_locations
      robots_sitemap_locations + Explore::Sitemap::Locations.new
    end
  end
end
