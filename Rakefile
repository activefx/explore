# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/**/*.rb"
end

begin
  require "yard"
  YARD::Rake::YardocTask.new do |t|
    t.files = ["lib/**/*.rb"]
    t.options = ["--output-dir", "doc", "--readme", "README.md"]
  end
rescue LoadError
  desc "Generate YARD documentation (YARD not available)"
  task :yard do
    abort "YARD is not available. Install it with: gem install yard"
  end
end

desc "Start an interactive console with the gem's files loaded"
task :console do
  require "irb"
  require "bundler/setup"
  $LOAD_PATH.unshift File.expand_path("lib", __dir__)
  require "explore"
  ARGV.clear
  IRB.start
end

task default: %i[test]
