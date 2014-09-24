# -*- coding: utf-8 -*-
require_relative "../test_helper.rb"
require 'stringio'

class ClientTest < Raygun::UnitTest

  class TestException < StandardError; end

  class FakeActionDispatcherIp
    attr_reader :ip
    def initialize remote_ip
      @ip = remote_ip
    end
    def to_s
      return ip
    end
  end

  def setup
    super
    @client = Raygun::Client.new
    fake_successful_entry
  end

  def test_api_key_required_exception
    Raygun.configuration.api_key = nil

    assert_raises Raygun::ApiKeyRequired do
      second_client = Raygun::Client.new
    end
  end

  def test_track_exception
    response = Raygun.track_exceptions do
      raise TestException.new
    end

    assert response.success?
  end

  def test_unicode
    e = TestException.new('日本語のメッセージ')

    assert_silent { @client.track_exception(e) }
  end

  def test_bad_encoding
    bad_message   = (100..1000).to_a.pack('c*').force_encoding('utf-8')
    bad_exception = TestException.new(bad_message)

    assert !bad_message.valid_encoding?
    assert_silent { @client.track_exception(bad_exception) }
  end

end
