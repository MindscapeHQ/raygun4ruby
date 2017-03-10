# -*- coding: utf-8 -*-
require_relative "../test_helper.rb"
require 'stringio'

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

  def setup_logging
    logger = FakeLogger.new
    Raygun.configuration.debug = true
    Raygun.configuration.logger = logger

    logger
  end
end
