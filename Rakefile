#!/usr/bin/env rake
require "bundler/gem_tasks"

require "rake/testtask"

namespace :test do

  desc "Test the basics of the adapter"
  Rake::TestTask.new(:units) do |t|
    t.test_files = FileList["test/unit/*_test.rb"]
    t.verbose = true
  end

  desc "Run a test against the live API"
  Rake::TestTask.new(:integration) do |t|
    t.test_files = FileList["test/integration/*_test.rb"]
    t.verbose = true
  end

end

task default: "test:units"
