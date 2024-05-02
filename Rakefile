require "bundler/setup"
require "bundler/gem_tasks"

require "appraisal"
require "rake/testtask"

namespace :test do

  desc "Test the basics of the adapter"
  Rake::TestTask.new(:units) do |t|
    t.test_files = FileList["test/unit/*_test.rb"]
  end

  desc "Run a test against the live API"
  Rake::TestTask.new(:integration) do |t|
    t.test_files = FileList["test/integration/*_test.rb"]
  end

  begin
    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new(:spec)

  rescue LoadError
  end
end

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["CI"]
  task default: :appraisal
else
  task default: ["test:units", "test:spec"]
end
