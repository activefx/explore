# frozen_string_literal: true

# TODO: https://x.com/alfonsusac/status/1905622097449095285

module Explore
  class Sitemaps
    PRIMARY = [
      "sitemap.xml",
      "sitemap.xml.gz",
      "sitemap_index.xml",
      "sitemap-index.xml",
      "sitemapindex.xml",
      "sitemap_index.xml.gz",
      "sitemap-index.xml.gz",
      "sitemapindex.xml.gz",
      "wp-sitemap.xml", # wordpress
      "sitemap/sitemap-index.xml",
      "sitemap/sitemap-index.xml.gz",
      "sitemap/sitemap_index.xml",
      "sitemap/sitemap_index.xml.gz",
      "sitemaps/sitemap_index.xml",
      "sitemaps/sitemap_index.xml.gz",
      "sitemaps/sitemap-index.xml",
      "sitemaps/sitemap-index.xml.gz",
      "sitemap/index.xml",
      "sitemap/index.xml.gz",
      "sitemap/index-sitemap.xml",
      "sitemap/index-sitemap.xml.gz",
      "sitemap-all.xml",
      "sitemap-all.xml.gz",
      "sitemap_index/xml",
      # "?feed=sitemap", # wordpress, can respond successfully if not a sitemap
      "feed/sitemap",
      "feed/sitemap.rss",
      "feed/sitemap.xml",
      "feed/sitemap.php",
      "site_map.xml",
      "sitemap1.xml"
    ].freeze

    HTML = [
      "sitemap",
      "sitemap.html",
      "sitemap.php",
      "sitemap.txt",
      "sitemap_index",
      "directory",
      "directory.html"
    ].freeze

    SPECIALIZED = [
      "post-sitemap.xml", # wordpress
      "page-sitemap.xml", # wordpress
      "category-sitemap.xml", # wordpress
      "sitemap-categories.xml.gz",
      "sitemap/categories.xml.gz",
      "sitemaps/categories.xml.gz",
      "sitemap.categories.xml.gz",
      "tag-sitemap.xml", # wordpress
      "video-sitemap.xml",
      "image-sitemap.xml",
      "sitemap-images.xml.gz"
    ].freeze

    NEWS = [
      "sitemap_news.xml",
      "sitemap-news.xml",
      "news-sitemap.xml",
      "sitemap/news.xml",
      "sitemap.news.xml",
      "sitemap_news.xml.gz",
      "sitemap-news.xml.gz",
      "sitemap/news.xml.gz",
      "sitemap.news.xml.gz",
      "news-sitemap.xml.gz",
      "google-news-sitemap.xml",
      "google_news-sitemap.xml",
      "sitemap-google-news.xml",
      # "?feed=sitemap-news", # wordpress, can respond successfully if not a sitemap
      "news.xml"
    ].freeze

    FEEDS = [
      "rss",
      "atom",
      "feed",
      "rss2",
      "rss.xml",
      "atom.xml",
      "feed.xml",
      "rss2.xml",
      "feed.json",
      "feed/comments",
      "feeds/posts/default",
      "feed/rss",
      "feed/atom",
      "feed/rdf",
      "feed/rss2",
      "feed/rss.xml",
      "feed/atom.xml",
      "feed.rss.xml",
      "feed.atom.xml",
      "mrss.xml",
      "feed.php",
      "feed.rss",
      "?feed=rss",
      "?feed=atom",
      "?feed=rdf",
      "?feed=rss2",
      "?feed=json",
      "feed_rss.xml"
    ].freeze

    # TODO: CMS specific: https://trends.builtwith.com/cms

    DEFAULT_OPTIONS = {
      method: :get,
      allow_redirections: true,
      connection_timeout: 5,
      read_timeout: 10,
      retries: 2,
      faraday_options: {
        redirect: {
          limit: 3
        }
      }
    }.freeze

    # def self.connection
    #   Faraday.new({ headers: { user_agent: "Explore Sitemaps" } }) do |conn|
    #     conn.use Faraday::FollowRedirects::Middleware, limit: 1, standards_compliant: true
    #     conn.options.timeout = 5
    #   end
    # end

    # attr_reader :root_url, :list

    # def initialize(root_url:,
    #   check: [Explore::Sitemaps::PRIMARY, Explore::Sitemaps::HTML],
    #   connection: self.class.connection
    # )
    #   unless root_url.to_s.last == "/"
    #     raise ArgumentError.new("root_url must end in a trailing slash")
    #   end
    #   @root_url = root_url
    #   @list = check.flatten
    #   @connection = connection
    # end

    # # Should only be called as a background job
    # #
    # # success?
    # # status
    # # env.url.to_s
    # # headers["last-modified"]
    # # headers["content-type"]
    # # headers["content-encoding"]
    # def call
    #   list.each_with_index do |sitemap_path, index|
    #     url = root_url + sitemap_path
    #     response = @connection.head(url)
    #     # Return the last response regardless of success
    #     break response if response.success? || (index == list.length - 1)
    #     sleep 1 # dont flood the site with sitemap checks
    #   end
    # end

    # TODO: Fetch webpage, check meta links
    #   As a last resort, grab all domain links on the homepage
    #   <link rel="sitemap" type="application/xml" title="Sitemap" href="/sitemap.xml">
  end
end
