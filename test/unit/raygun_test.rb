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

  class ErrorSubscriberTest < Raygun::UnitTest
    def setup
      Raygun.setup do |c|
        c.api_key = "test"
        c.silence_reporting = false
        c.debug = true
        c.register_rails_error_handler = true
      end

      Raygun::Railtie.setup_error_subscriber
    end

    def test_registers_with_rails
      if ::Rails.version.to_f >= 7.0
        assert Rails.error.instance_variable_get("@subscribers").any? { |s| s.is_a?(Raygun::ErrorSubscriber) }
      end
    end

    def test_reports_exceptions
      if ::Rails.version.to_f >= 7.0
        stub_request(:post, "https://api.raygun.com/entries").to_return(status: 202)

        Rails.error.handle do
          raise StandardError.new("test rails handling")
        end
      end
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

  def test_retries 
    failsafe_logger = FakeLogger.new
    Raygun.setup do |c|
      c.error_report_max_attempts = 3
      c.failsafe_logger = failsafe_logger
    end  

    WebMock.reset!
    report_request = stub_request(:post, "https://api.raygun.com/entries").to_timeout

    error = StandardError.new
    Raygun.track_exception(error)

    assert_requested report_request, times: 3

    assert_match(/Gave up reporting exception to Raygun after 3 retries/, failsafe_logger.get)
  ensure
    Raygun.reset_configuration
  end

  def test_raising_on_retry_failure
    Raygun.setup do |c|
      c.error_report_max_attempts = 1
      c.raise_on_failed_error_report = true
    end  

    report_request = stub_request(:post, "https://api.raygun.com/entries").to_timeout

    error = StandardError.new

    assert_raises(StandardError) do
      Raygun.track_exception(error)
      assert_requested report_request
    end

  ensure
    Raygun.reset_configuration
  end
end
