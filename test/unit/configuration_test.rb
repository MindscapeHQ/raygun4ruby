require_relative "../test_helper.rb"

class ConfigurationTest < Raygun::UnitTest

  class TestException < StandardError; end
  class Test2Exception < StandardError; end

  def setup
    Raygun.setup do |config|
      config.api_key = "a test api key"
      config.version = 9.9
    end
  end

  def teardown
    Raygun.reset_configuration
  end

  def test_setting_api_key_and_version
    assert_equal 9.9,              Raygun.configuration.version
    assert_equal "a test api key", Raygun.configuration.api_key
  end

  def test_hash_style_access
    assert_equal 9.9, Raygun.configuration[:version]
  end

  def test_enable_reporting
    Raygun.configuration.enable_reporting = false

    # should be no API call
    assert_nil Raygun.track_exception(TestException.new)
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

  def test_ignoring_multiple_exceptions
    Raygun.configuration.ignore << [TestException.to_s, Test2Exception.to_s]

    assert_nil Raygun.track_exception(TestException.new)
    assert_nil Raygun.track_exception(Test2Exception.new)
  end

  def test_default_values
    assert_equal({}, Raygun.configuration.custom_data)
  end

  def test_default_tags_set
    assert_equal([], Raygun.configuration.tags)
  end

  def test_overriding_defaults
    Raygun.default_configuration.custom_data = { robby: "robot" }
    assert_equal({ robby: "robot" }, Raygun.configuration.custom_data)

    Raygun.configuration.custom_data = { sally: "stegosaurus" }
    assert_equal({ sally: "stegosaurus" }, Raygun.configuration.custom_data)
  end

  def test_debug
    Raygun.setup do |config|
      config.debug = true
    end

    assert_equal Raygun.configuration.debug, true
  end

  def test_debug_default_set
    assert_equal false, Raygun.configuration.debug
  end

  def test_setting_filter_paramters_to_proc
    Raygun.setup do |config|
      config.filter_parameters do |hash|
        # Don't need to do anything :)
      end
    end

    assert Raygun.configuration.filter_parameters.is_a?(Proc)
  ensure
    Raygun.configuration.filter_parameters = nil
  end

  def test_filter_payload_with_whitelist_default
    assert_equal(false, Raygun.configuration.filter_payload_with_whitelist)
  end

  def test_setting_whitelist_payload_keys_to_proc
    Raygun.setup do |config|
      config.whitelist_payload_shape do |hash|
        # No-op
      end
    end

    assert Raygun.configuration.whitelist_payload_shape.is_a?(Proc)
    ensure
      Raygun.configuration.whitelist_payload_shape = nil
  end

  def test_setting_custom_data_to_proc
    Raygun.setup do |config|
      config.custom_data do |exception, env|
        # No-op
      end
    end

    assert Raygun.configuration.custom_data.is_a?(Proc)
  ensure
      Raygun.configuration.custom_data = nil
  end

  def test_setting_custom_data_to_hash
    Raygun.setup do |config|
      config.custom_data = {}
    end

    assert Raygun.configuration.custom_data.is_a?(Hash)
  ensure
      Raygun.configuration.custom_data = nil
  end

  def test_setting_tags_to_array
    Raygun.setup do |c|
      c.tags = ['test']
    end

    assert_equal Raygun.configuration.tags, ['test']
  end

  def test_setting_tags_to_proc
    Raygun.setup do |c|
      c.tags = ->(exception, env) {}
    end

    assert Raygun.configuration.tags.is_a?(Proc)
  end

  def test_api_url_default
    assert_equal "https://api.raygun.io/", Raygun.configuration.api_url
  end

  def test_setting_breadcrumb_level
    Raygun.setup do |config|
      config.breadcrumb_level = :info
    end

    assert_equal :info, Raygun.configuration.breadcrumb_level
  end

  def test_setting_breadcrumb_level_to_bad_value
    logger = setup_logging

    Raygun.setup do |config|
      config.breadcrumb_level = :invalid
    end

    assert_equal :info, Raygun.configuration.breadcrumb_level
    assert(
      logger.get.include?("unknown breadcrumb level"),
      "unknown breadcrumb level message was not logged"
    )
  end

  def test_breadcrumb_level_default
    assert_equal :info, Raygun.configuration.breadcrumb_level
  end

  def test_record_raw_data_default
    assert_equal false, Raygun.configuration.record_raw_data
  end

  def test_send_in_background_default
    assert_equal false, Raygun.configuration.send_in_background
  end

  def test_error_report_send_timeout_default
    assert_equal 10, Raygun.configuration.error_report_send_timeout
  end

  def test_enable_reporting_default
    assert_equal true, Raygun.configuration.enable_reporting
  end
end
