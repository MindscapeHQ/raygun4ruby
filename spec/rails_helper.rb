ENV['RAILS_ENV'] ||= 'test'
require "rails_applications/#{ENV.fetch('TESTING_RAILS_VERSION', '6.1.4')}/config/environment"

require 'rspec/rails'
