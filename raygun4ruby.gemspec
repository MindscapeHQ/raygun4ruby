# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "raygun/version"

Gem::Specification.new do |spec|
  spec.name          = "raygun4ruby"
  spec.version       = Raygun::VERSION
  spec.authors       = ["Mindscape", "Nik Wakelin"]
  spec.email         = ["hello@raygun.com"]
  spec.description   = %q{Ruby Adapter for Raygun}
  spec.summary       = %q{This gem provides support for Ruby and Ruby on Rails for the Raygun.com error reporter}
  spec.homepage      = "https://raygun.com"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.0"

  spec.files         = `git ls-files | grep -Ev "^(test)"`.split("\n")
  spec.test_files    = `git ls-files -- test/*`.split("\n")

  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "httparty", "> 0.13.7"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "rack"
  spec.add_runtime_dependency "concurrent-ruby"

  spec.add_development_dependency "bundler", ">= 2.3"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "minitest", "~> 5.11"
  spec.add_development_dependency "redis-namespace", ">= 1.3.1"
  spec.add_development_dependency "resque"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "webmock"

  spec.add_development_dependency "capybara"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "launchy"
  spec.add_development_dependency "simplecov"
end
