ENV['RAILS_ENV'] ||= 'test'
require "rails"

require "rails_applications/#{Rails::VERSION::STRING}/config/environment"

require "rspec/rails"
