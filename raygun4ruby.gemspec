# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'raygun/version'

Gem::Specification.new do |spec|
  spec.name          = "raygun4ruby"
  spec.version       = Raygun::VERSION
  spec.authors       = ["Nik Wakelin"]
  spec.email         = ["me@nikwakelin.com"]
  spec.description   = %q{Ruby Adapter for Raygun.io}
  spec.summary       = %q{Ruby Adapter for Raygun.io}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "httparty", "~> 0.11"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "rack"
  spec.add_runtime_dependency "minitest",   "~> 5.0"

  spec.add_development_dependency "bundler", ">= 1.1"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "fakeweb", ["~> 1.3"]
  spec.add_development_dependency "timecop"
end
