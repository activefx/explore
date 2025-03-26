# frozen_string_literal: true

require_relative "lib/explore/version"

Gem::Specification.new do |spec|
  spec.name = "explore"
  spec.version = Explore::VERSION
  spec.authors = ["Matt Solt"]
  spec.email = ["mattsolt@gmail.com"]

  spec.summary = "A Ruby port of URI.js providing a chainable API for URI manipulation"
  spec.description = "Explore::Uri is a Ruby port of URI.js that provides a chainable API for manipulating URIs with support for parsing, modifying, and comparing URIs."
  spec.homepage = "https://github.com/msolt/explore"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "zeitwerk", "~> 2.6"
  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "addressable", "~> 2.8"
  spec.add_dependency "public_suffix", "~> 6.0"
  spec.add_dependency "faraday", "~> 2.12"
  spec.add_dependency "faraday-cookie_jar", "~> 0.0"
  spec.add_dependency "faraday-encoding", "~> 0.0"
  spec.add_dependency "faraday-follow_redirects", "~> 0.3"
  spec.add_dependency "faraday-gzip", "~> 3.0"
  spec.add_dependency "faraday-http-cache", "~> 2.5"
  spec.add_dependency "faraday-retry", "~> 2.2"
  spec.add_dependency "gort", "~> 0.1"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.6"
  spec.add_development_dependency "vcr", "~> 6.3"
  spec.add_development_dependency "webmock", "~> 3.25"
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
