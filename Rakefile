# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/**/*.rb"
end

desc "Start an interactive console with the gem's files loaded"
task :console do
  require "irb"
  require "bundler/setup"
  $LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
  require "explore"
  ARGV.clear
  IRB.start
end

task default: %i[test]
