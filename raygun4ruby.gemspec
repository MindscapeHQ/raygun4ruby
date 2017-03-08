# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'raygun/version'

Gem::Specification.new do |spec|
  spec.name          = "raygun4ruby"
  spec.version       = Raygun::VERSION
  spec.authors       = ["Mindscape", "Nik Wakelin"]
  spec.email         = ["hello@raygun.io"]
  spec.description   = %q{Ruby Adapter for Raygun.io}
  spec.summary       = %q{This gem provides support for Ruby and Ruby on Rails for the Raygun.io error reporter}
  spec.homepage      = "http://raygun.io"
  spec.license       = "MIT"

  spec.files         = `git ls-files | grep -Ev '^(test)'`.split("\n")
  spec.test_files    = `git ls-files -- test/*`.split("\n")

  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "httparty", "> 0.13.7"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "rack"

  spec.add_development_dependency "bundler", ">= 1.1"
  spec.add_development_dependency "rake", "0.9.6"
  spec.add_development_dependency "fakeweb", ["~> 1.3"]
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "minitest", "~> 4.2"
  spec.add_development_dependency "redis-namespace", ">= 1.3.1"
  spec.add_development_dependency "resque"
  spec.add_development_dependency "sidekiq", [">= 3", "< 3.2.2"]
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "pry"
end
