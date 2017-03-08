ENV['RACK_ENV'] = 'test'
require_relative "../lib/raygun.rb"
require "minitest/autorun"
require "minitest/pride"
require "fakeweb"
require "timecop"
require "mocha/mini_test"

class NoApiKey < StandardError; end

class Raygun::IntegrationTest < Minitest::Unit::TestCase

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

class Raygun::UnitTest < MiniTest::Unit::TestCase

  def setup
    FakeWeb.allow_net_connect = false
    Raygun.configuration.api_key = "test api key"
  end

  def fake_successful_entry
    FakeWeb.register_uri(:post, "https://api.raygun.io/entries", body: "", status: 202)
  end

  def teardown
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = true
    reset_configuration
  end

  def reset_configuration
    Raygun.configuration = Raygun::Configuration.new
  end

end
