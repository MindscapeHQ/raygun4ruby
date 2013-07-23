require "minitest"
require "minitest/pride"
require_relative "../lib/raygun.rb"

class NoApiKey < StandardError; end

class Raygun::IntegrationTest < Minitest::Test

  def setup
    Raygun.setup do |config|
      config.api_key = File.open(File.expand_path("~/.raygun4ruby-test-key"), "rb").read
    end

  rescue Errno::ENOENT
    raise NoApiKey.new("Place a valid Raygun API key into ~/.raygun4ruby-test-key to run integration tests") unless api_key
  end

  def teardown
  end

end