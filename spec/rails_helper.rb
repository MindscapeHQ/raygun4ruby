ENV['RAILS_ENV'] ||= 'test'
require "rails_applications/#{ENV.fetch('TESTING_RAILS_VERSION', '4.2.11')}/config/environment"

require 'rspec/rails'
