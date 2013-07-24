require_relative "../test_helper.rb"

class ConfigurationTest < Raygun::UnitTest

  class TestException < StandardError; end

  def setup
    Raygun.setup do |config|
      config.api_key = "a test api key"
      config.version = 9.9
    end
  end

  def test_setting_api_key_and_version
    assert_equal 9.9,              Raygun.configuration.version
    assert_equal "a test api key", Raygun.configuration.api_key
  end

  def test_hash_style_access
    assert_equal 9.9, Raygun.configuration[:version]
  end

  def test_silence_reporting
    Raygun.configuration.silence_reporting = true

    # nothing returned as there's no HTTP call
    assert_nil Raygun.track_exception(TestException.new)
  end

  def test_ignoring_exceptions
    Raygun.configuration.ignore << TestException.to_s

    assert_nil Raygun.track_exception(TestException.new)
  end

end