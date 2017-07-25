#!/usr/bin/env rake
require "bundler/gem_tasks"
#require "rspec/core/rake_task"
require "rake/testtask"

#RSpec::Core::RakeTask.new(:spec)
#task :default => :spec
desc 'Run test_unit based test'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = Dir["test/test_*.rb"].sort
  test.verbose = true
end

task :default => :test
