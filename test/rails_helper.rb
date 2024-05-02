ENV['RAILS_ENV'] ||= 'test'
require "rails"

major_minor_patch = Rails::VERSION::STRING.split(".").first(3).join(".")

require_relative "../spec/rails_applications/#{major_minor_patch}/config/environment"