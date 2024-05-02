# -*- coding: utf-8 -*-
require_relative "../test_helper.rb"

class RaygunTest < Raygun::UnitTest
  def test_raygun_is_not_configured_with_no_api_key
    Raygun.configuration.api_key = nil
    assert !Raygun.configured?
  end

  def test_should_report_logs_silence_reporting_when_debug_is_on
    logger = setup_logging
    Raygun.configuration.silence_reporting = true
    Raygun.send(:should_report?, Exception.new)

    assert logger.get.include?("silence_reporting"), "silence_reporting was not logged"
  end

  def test_should_report_logs_ignored_exceptions_when_debug_is_on
    logger = setup_logging
    Raygun.configuration.ignore = ["Exception"]
    Raygun.send(:should_report?, Exception.new)

    assert logger.get =~ /skipping reporting of.*Exception.*/, "ignored exception was not logged"
  end

  class BackgroundSendTest < Raygun::UnitTest
    def setup
      @failsafe_logger = FakeLogger.new
      Raygun.setup do |c|
        c.silence_reporting = false
        c.send_in_background = true
        c.api_url = "http://example.api"
        c.api_key = "foo"
        c.debug = false
        c.failsafe_logger = @failsafe_logger
      end
    end

    def test_breadcrumb_context_passed
      Raygun::Breadcrumbs::Store.initialize      
      Raygun.record_breadcrumb(message: "mmm crumbly")
      assert Raygun::Breadcrumbs::Store.any?

      stub_request(:post, "http://example.api/entries")
        .with(body: hash_including(breadcrumbs: [ hash_including(message: "mmm crumbly") ]))
        .to_return(status: 202)

      Raygun.track_exception(StandardError.new)
      Raygun.wait_for_futures
    ensure
      Raygun::Breadcrumbs::Store.clear
    end

    def test_failsafe_reported_on_timeout
      stub_request(:post, "http://example.api/entries").to_timeout

      error = StandardError.new

      Raygun.track_exception(error)

      Raygun.wait_for_futures
      assert_match(/Problem reporting exception to Raygun/, @failsafe_logger.get)
    end

  end

  def test_reset_configuration
    Raygun.setup do |c|
      c.api_url = "http://test.api"
    end

    original_api_url = Raygun.configuration.api_url
    Raygun.reset_configuration
    assert_equal Raygun.default_configuration.api_url, Raygun.configuration.api_url
    refute_equal original_api_url, Raygun.configuration.api_url
  end
end
