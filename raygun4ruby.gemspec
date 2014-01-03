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

  spec.files         = ["lib/raygun.rb",
                        "lib/raygun/client.rb",
                        "lib/raygun/configuration.rb",
                        "lib/raygun/middleware/rack_exception_interceptor.rb",
                        "lib/raygun/middleware/rails_insert_affected_user.rb",
                        "lib/raygun/railtie.rb",
                        "lib/raygun/version.rb",
                        "lib/raygun4ruby.rb",
                        "lib/generators/raygun/install_generator.rb",
                        "lib/raygun/testable.rb",
                        "lib/tasks/raygun.tasks",
                        "lib/resque/failure/raygun.rb",
                        "README.md"]

  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "httparty", "~> 0.11"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "rack"

  spec.add_development_dependency "bundler", ">= 1.1"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "fakeweb", ["~> 1.3"]
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "minitest", "~> 4.2"
  spec.add_development_dependency "resque"
end
