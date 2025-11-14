# frozen_string_literal: true

module Explore
  # Represents a web resource identified by a URI
  class Resource
    attr_reader :uri, :domain

    # Initialize a new Resource
    # @param input [String, URI] the URI to explore
    def initialize(input, **_options)
      @uri = Explore::URI.new(input)
      @domain = Explore::Domain.new(@uri.host, ignore_private: true)
      @head = nil
      @robots = nil
    end

    # def user_agent
    #   # https://intoli.com/blog/user-agents/
    # end

    # Fetch or return cached HTTP head request information
    # @return [Explore::Head] head request information
    def head
      @head ||= Explore::Head.new(uri)
    end

    def head?
      !!@head && @head.success?
    end

    def robots_txt_url
      if head?
        "#{head.request.url.scheme}://#{head.request.url.host}/robots.txt"
      else
        "#{uri.scheme}://#{uri.host}/robots.txt"
      end
    end

    def robots
      @robots ||= Explore::Robots.new(uri: robots_txt_url)
    end

    def robots_sitemap_locations
      sources = robots.sitemaps.map do |sitemap|
        uri = Explore::URI.new(sitemap)
        Explore::Sitemap::Source.new(
          path: uri.path,
          origin: uri.origin,
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

    # With the tag :robots, this method will return the sitemap sources from the robots.txt file.
    # To check additional sources, pass an array of tags. Common tags include :robots, :common, :extended,
    # :news, and :content. For a full list, see Explore::Sitemap::Locations::DATA.
    # To check all data file sources, use the tag :all. Be sure to include the :robots tag to check
    # the sitemap sources from the robots.txt file if needed when using the :all tag.
    def sitemaps(sources: sitemap_locations, crawl_delay: 0.1, strategy: :all, tags: [:robots])
      sources = sources.find_by_tags(tags)
      search = Explore::Sitemap::Search.new(sources, crawl_delay: crawl_delay, strategy: strategy)
      search.run
    end

    # subdomains
    # whois
    # dns
    # technologies

    # Reset cached head request information
    # @return [nil]
    def reset!
      @head = nil
    end

    private

    def sitemap_locations
      robots_sitemap_locations + Explore::Sitemap::Locations.new
    end
  end
end
