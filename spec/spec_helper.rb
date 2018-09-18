require 'rubygems'
require 'bundler/setup'

require "timecop"
require 'webmock/rspec'

# Coverage
#require 'simplecov'
#SimpleCov.start do
  #add_filter '/spec/'
#end

# This Gem
require 'raygun'

#Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  # config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

class FakeLogger
  def initialize
    @logger = StringIO.new
  end

  def info(message)
    @logger.write(message)
  end

  def reset
    @logger.string = ""
  end

  def get
    @logger.string
  end
end
