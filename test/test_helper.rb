ENV['RACK_ENV'] = 'test'
require "minitest/autorun"
require "minitest/pride"
require "timecop"
require "mocha/minitest"
require "stringio"
require "webmock/minitest"

require_relative "./rails_helper"
require_relative "../lib/raygun.rb"

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

class NoApiKey < StandardError; end

class Raygun::IntegrationTest < Minitest::Test

  def setup
    Raygun.setup do |config|
      config.api_key = File.open(File.expand_path("~/.raygun4ruby-test-key"), "rb").read
      config.version = Raygun::VERSION
    end

  rescue Errno::ENOENT
    raise NoApiKey.new("Place a valid Raygun API key into ~/.raygun4ruby-test-key to run integration tests") unless api_key
  end

  def teardown
  end

end

class Raygun::UnitTest < Minitest::Test

  def setup
    Raygun.configuration.api_key = "test api key"
  end

  def teardown
    reset_configuration
  end

  def fake_successful_entry
    stub_request(:post, 'https://api.raygun.com/entries').to_return(status: 202)
  end

  def reset_configuration
    Raygun.configuration = Raygun::Configuration.new
  end

  def setup_logging
    logger = FakeLogger.new
    Raygun.configuration.debug = true
    Raygun.configuration.logger = logger

    logger
  end
end
