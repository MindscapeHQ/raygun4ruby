ENV['RAILS_ENV'] ||= 'test'
require "rails"

major_minor_patch = Rails::VERSION::STRING.split(".").first(3).join(".")

require "rails_applications/#{major_minor_patch}/config/environment"

require "rspec/rails"
