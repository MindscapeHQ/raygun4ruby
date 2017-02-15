# -*- coding: utf-8 -*-
require_relative "../test_helper.rb"
require 'stringio'

class ClientTest < Raygun::UnitTest

  class TestException < StandardError; end
  class NilMessageError < StandardError
    def message
      nil
    end
  end

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

  def test_api_key_required_message
    Raygun.configuration.api_key = nil

    $stderr.expects(:puts).with(Raygun::Client::NO_API_KEY_MESSAGE).once
    second_client = Raygun::Client.new
  end

  def test_track_exception
    response = Raygun.track_exceptions do
      raise TestException.new
    end

    assert response.success?
  end

  def test_error_details
    e = TestException.new("A test message")
    e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                     "/another/path/foo.rb:1234:in `block (3 levels) run'"])

    expected_hash = {
      className: "ClientTest::TestException",
      message:   e.message,
      stackTrace: [
        { lineNumber: "123",  fileName: "/some/folder/some_file.rb", methodName: "some_method_name" },
        { lineNumber: "1234", fileName: "/another/path/foo.rb",      methodName: "block (3 levels) run"}
      ]
    }

    assert_equal expected_hash, @client.send(:error_details, e)
  end

  def test_error_details_with_nil_message
    e = NilMessageError.new
    expected_message = ""
    assert_equal expected_message, @client.send(:error_details, e)[:message]
  end

  def test_client_details
    expected_hash = {
      name:      Raygun::CLIENT_NAME,
      version:   Raygun::VERSION,
      clientUrl: Raygun::CLIENT_URL
    }

    assert_equal expected_hash, @client.send(:client_details)
  end


  def test_version
    Raygun.setup do |config|
      config.version = 123
    end

    assert_equal 123, @client.send(:version)
  end

  def test_affected_user
    e             = TestException.new("A test message")
    test_env      = { "raygun.affected_user" => { :identifier => "somepooruser@yourapp.com" } }
    expected_hash = test_env["raygun.affected_user"]

    assert_equal expected_hash, @client.send(:build_payload_hash, e, test_env)[:details][:user]
  end

  def test_tags
    configuration_tags = %w{alpha beta gaga}
    explicit_env_tags  = %w{one two three four}
    rack_env_tag       = %w{test}

    Raygun.setup do |config|
      config.tags = configuration_tags
    end

    e             = TestException.new("A test message")
    test_env      = { tags: explicit_env_tags }
    expected_tags =  configuration_tags + explicit_env_tags + rack_env_tag

    assert_equal expected_tags, @client.send(:build_payload_hash, e, test_env)[:details][:tags]
  end

  def test_hostname
    assert_equal Socket.gethostname, @client.send(:hostname)
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

  def test_backtrace_without_method_name

    expected = {
      lineNumber: "123",
      fileName:   "/some/folder/some_file.rb",
      methodName: "(none)"
    }

    # note lack of "in method name" in this stack trace line
    assert_equal expected, @client.send(:stack_trace_for, "/some/folder/some_file.rb:123")
  end

  def test_full_payload_hash
    Timecop.freeze do
      Raygun.configuration.version = 123
      e = TestException.new("A test message")
      e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                       "/another/path/foo.rb:1234:in `block (3 levels) run'"])

      grouping_key = "my custom group"

      expected_hash = {
        occurredOn: Time.now.utc.iso8601,
        details: {
          machineName:    Socket.gethostname,
          version:        123,
          client: {
            name:      Raygun::CLIENT_NAME,
            version:   Raygun::VERSION,
            clientUrl: Raygun::CLIENT_URL
          },
          error: {
            className: "ClientTest::TestException",
            message:   e.message,
            stackTrace: [
              { lineNumber: "123",  fileName: "/some/folder/some_file.rb", methodName: "some_method_name" },
              { lineNumber: "1234", fileName: "/another/path/foo.rb",      methodName: "block (3 levels) run"}
            ]
          },
          userCustomData: {},
          tags:           ["test"],
          request:        {},
          groupingKey:    grouping_key
        }
      }

      assert_equal expected_hash, @client.send(:build_payload_hash, e, { grouping_key: grouping_key })
    end
  end

  def test_getting_request_information
    sample_env_hash = {
      "SERVER_NAME"=>"localhost",
      "REQUEST_METHOD"=>"GET",
      "REQUEST_PATH"=>"/",
      "PATH_INFO"=>"/",
      "QUERY_STRING"=>"a=b&c=4945438",
      "REQUEST_URI"=>"/?a=b&c=4945438",
      "HTTP_VERSION"=>"HTTP/1.1",
      "HTTP_HOST"=>"localhost:3000",
      "HTTP_CONNECTION"=>"keep-alive",
      "HTTP_CACHE_CONTROL"=>"max-age=0",
      "HTTP_ACCEPT"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.22 Safari/537.36",
      "HTTP_ACCEPT_ENCODING"=>"gzip,deflate,sdch",
      "HTTP_ACCEPT_LANGUAGE"=>"en-US,en;q=0.8",
      "HTTP_COOKIE"=>"cookieval",
      "GATEWAY_INTERFACE"=>"CGI/1.2",
      "SERVER_PORT"=>"3000",
      "SERVER_PROTOCOL"=>"HTTP/1.1",
      "SCRIPT_NAME"=>"",
      "REMOTE_ADDR"=>"127.0.0.1"
    }

    expected_hash = {
      hostName:    "localhost",
      url:         "/",
      httpMethod:  "GET",
      iPAddress:   "127.0.0.1",
      queryString: { "a" => "b", "c" => "4945438" },
      headers:     { "Version"=>"HTTP/1.1", "Host"=>"localhost:3000", "Connection"=>"keep-alive", "Cache-Control"=>"max-age=0", "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "User-Agent"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.22 Safari/537.36", "Accept-Encoding"=>"gzip,deflate,sdch", "Accept-Language"=>"en-US,en;q=0.8", "Cookie"=>"cookieval" },
      form:        {},
      rawData:     {}
    }

    assert_equal expected_hash, @client.send(:request_information, sample_env_hash)
  end

  def test_getting_request_information_with_nil_env
    assert_equal({}, @client.send(:request_information, nil))
  end

  def test_non_form_parameters
    put_body_env_hash = {
      "SERVER_NAME"=>"localhost",
      "REQUEST_METHOD"=>"PUT",
      "REQUEST_PATH"=>"/",
      "PATH_INFO"=>"/",
      "QUERY_STRING"=>"",
      "REQUEST_URI"=>"/",
      "HTTP_VERSION"=>"HTTP/1.1",
      "HTTP_HOST"=>"localhost:3000",
      "HTTP_CONNECTION"=>"keep-alive",
      "HTTP_CACHE_CONTROL"=>"max-age=0",
      "HTTP_ACCEPT"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.22 Safari/537.36",
      "HTTP_ACCEPT_ENCODING"=>"gzip,deflate,sdch",
      "HTTP_ACCEPT_LANGUAGE"=>"en-US,en;q=0.8",
      "HTTP_COOKIE"=>"cookieval",
      "GATEWAY_INTERFACE"=>"CGI/1.2",
      "SERVER_PORT"=>"3000",
      "SERVER_PROTOCOL"=>"HTTP/1.1",
      "SCRIPT_NAME"=>"",
      "REMOTE_ADDR"=>"127.0.0.1",
      "action_dispatch.request.parameters"=> { "a" => "b", "c" => "4945438", "password" => "swordfish" }
    }

    expected_form_hash = { "a" => "b", "c" => "4945438", "password" => "[FILTERED]" }

    assert_equal expected_form_hash, @client.send(:request_information, put_body_env_hash)[:rawData]
  end

  def test_filtering_parameters
    post_body_env_hash = sample_env_hash.merge(
      "rack.input"=>StringIO.new("a=b&c=4945438&password=swordfish")
    )

    expected_form_hash = { "a" => "b", "c" => "4945438", "password" => "[FILTERED]" }

    assert_equal expected_form_hash, @client.send(:request_information, post_body_env_hash)[:form]
  end

  def test_filtering_nested_params
    post_body_env_hash = sample_env_hash.merge(
      "rack.input" => StringIO.new("a=b&bank%5Bcredit_card%5D%5Bcard_number%5D=my_secret_bank_number&bank%5Bname%5D=something&c=123456&user%5Bpassword%5D=my_fancy_password")
    )

    expected_form_hash = { "a" => "b", "bank" => { "credit_card" => { "card_number" => "[FILTERED]" }, "name" => "something" }, "c" => "123456", "user" => { "password" => "[FILTERED]" } }

    assert_equal expected_form_hash, @client.send(:request_information, post_body_env_hash)[:form]
  end

  def test_filter_parameters_using_proc
    # filter any parameters that start with "nsa_only"
    Raygun.configuration.filter_parameters do |hash|
      hash.inject({}) do |sanitized_hash, pair|
        k, v = pair
        v = "[OUREYESONLY]" if k[0...8] == "nsa_only"
        sanitized_hash[k] = v
        sanitized_hash
      end
    end

    post_body_env_hash = sample_env_hash.merge(
      "rack.input" => StringIO.new("nsa_only_info=123&nsa_only_metadata=seekrit&something_normal=hello")
    )

    expected_form_hash = { "nsa_only_info" => "[OUREYESONLY]", "nsa_only_metadata" => "[OUREYESONLY]", "something_normal" => "hello" }

    assert_equal expected_form_hash, @client.send(:request_information, post_body_env_hash)[:form]
  ensure
    Raygun.configuration.filter_parameters = nil
  end

  def test_filter_parameters_using_array
    filter_params_as_from_rails = [:password]
    Raygun.configuration.filter_parameters = filter_params_as_from_rails

    parameters = {
      "something_normal" => "hello",
      "password" => "wouldntyouliketoknow",
      "password_confirmation" => "wouldntyouliketoknow",
      "PasswORD_weird_case" => "anythingatall"
    }

    expected_form_hash = {
      "something_normal" => "hello",
      "password" => "[FILTERED]",
      "password_confirmation" => "[FILTERED]",
      "PasswORD_weird_case" => "[FILTERED]"
    }

    post_body_env_hash = sample_env_hash.merge(
      "rack.input" => StringIO.new(URI.encode_www_form(parameters))
    )

    assert_equal expected_form_hash, @client.send(:request_information, post_body_env_hash)[:form]
  ensure
    Raygun.configuration.filter_parameters = nil
  end

  def test_ip_address_from_action_dispatch
    sample_env_hash = {
      "HTTP_VERSION"=>"HTTP/1.1",
      "HTTP_HOST"=>"localhost:3000",
      "HTTP_CONNECTION"=>"keep-alive",
      "HTTP_CACHE_CONTROL"=>"max-age=0",
      "HTTP_ACCEPT"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.22 Safari/537.36",
      "HTTP_ACCEPT_ENCODING"=>"gzip,deflate,sdch",
      "HTTP_ACCEPT_LANGUAGE"=>"en-US,en;q=0.8",
      "HTTP_COOKIE"=>"cookieval",
      "GATEWAY_INTERFACE"=>"CGI/1.2",
      "SERVER_PORT"=>"3000",
      "SERVER_PROTOCOL"=>"HTTP/1.1",
      "SCRIPT_NAME"=>"",
      "REMOTE_ADDR"=>"127.0.0.1",
      "action_dispatch.remote_ip"=> "123.456.789.012"
    }

    assert_equal "123.456.789.012", @client.send(:ip_address_from, sample_env_hash)
    assert_equal "123.456.789.012", @client.send(:request_information, sample_env_hash)[:iPAddress]
  end

  def test_ip_address_from_old_action_dispatch
    old_action_dispatch_ip = FakeActionDispatcherIp.new("123.456.789.012")
    sample_env_hash = {
      "HTTP_VERSION"=>"HTTP/1.1",
      "HTTP_HOST"=>"localhost:3000",
      "HTTP_CONNECTION"=>"keep-alive",
      "HTTP_CACHE_CONTROL"=>"max-age=0",
      "HTTP_ACCEPT"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.22 Safari/537.36",
      "HTTP_ACCEPT_ENCODING"=>"gzip,deflate,sdch",
      "HTTP_ACCEPT_LANGUAGE"=>"en-US,en;q=0.8",
      "HTTP_COOKIE"=>"cookieval",
      "GATEWAY_INTERFACE"=>"CGI/1.2",
      "SERVER_PORT"=>"3000",
      "SERVER_PROTOCOL"=>"HTTP/1.1",
      "SCRIPT_NAME"=>"",
      "REMOTE_ADDR"=>"127.0.0.1",
      "action_dispatch.remote_ip"=> old_action_dispatch_ip
    }

    assert_equal old_action_dispatch_ip, @client.send(:ip_address_from, sample_env_hash)
    assert_equal "123.456.789.012", @client.send(:request_information, sample_env_hash)[:iPAddress]
  end

  def test_ip_address_from_raygun_specific_key
    sample_env_hash = {
      "HTTP_VERSION"=>"HTTP/1.1",
      "HTTP_HOST"=>"localhost:3000",
      "HTTP_CONNECTION"=>"keep-alive",
      "HTTP_CACHE_CONTROL"=>"max-age=0",
      "HTTP_ACCEPT"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.22 Safari/537.36",
      "HTTP_ACCEPT_ENCODING"=>"gzip,deflate,sdch",
      "HTTP_ACCEPT_LANGUAGE"=>"en-US,en;q=0.8",
      "HTTP_COOKIE"=>"cookieval",
      "GATEWAY_INTERFACE"=>"CGI/1.2",
      "SERVER_PORT"=>"3000",
      "SERVER_PROTOCOL"=>"HTTP/1.1",
      "SCRIPT_NAME"=>"",
      "REMOTE_ADDR"=>"127.0.0.1",
      "raygun.remote_ip"=>"123.456.789.012"
    }

    assert_equal "123.456.789.012", @client.send(:ip_address_from, sample_env_hash)
    assert_equal "123.456.789.012", @client.send(:request_information, sample_env_hash)[:iPAddress]
  end

  def test_ip_address_returns_not_available_if_not_set
    sample_env_hash = {
      "HTTP_VERSION"=>"HTTP/1.1",
      "HTTP_HOST"=>"localhost:3000",
      "HTTP_CONNECTION"=>"keep-alive",
      "HTTP_CACHE_CONTROL"=>"max-age=0",
      "HTTP_ACCEPT"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.22 Safari/537.36",
      "HTTP_ACCEPT_ENCODING"=>"gzip,deflate,sdch",
      "HTTP_ACCEPT_LANGUAGE"=>"en-US,en;q=0.8",
      "HTTP_COOKIE"=>"cookieval",
      "GATEWAY_INTERFACE"=>"CGI/1.2",
      "SERVER_PORT"=>"3000",
      "SERVER_PROTOCOL"=>"HTTP/1.1",
      "SCRIPT_NAME"=>""
    }

    assert_equal "(Not Available)", @client.send(:ip_address_from, sample_env_hash)
  end

  def test_setting_up_http_proxy
    begin
      Raygun.configuration.proxy_settings[:address] = "http://proxy.com"
      Raygun::Client.expects(:http_proxy).with("http://proxy.com", "80", nil, nil)

      Raygun.track_exceptions do
        raise TestException.new
      end
    ensure
      Raygun.configuration.proxy_settings = {}
    end
  end

  def test_filter_payload_with_whitelist_default
    Raygun.configuration.filter_payload_with_whitelist = true

    e = TestException.new("A test message")
    e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                       "/another/path/foo.rb:1234:in `block (3 levels) run'"])
    
    details = @client.send(:build_payload_hash, e)[:details]
    assert_equal '[FILTERED]', details[:machineName]
    assert_equal '[FILTERED]', details[:version]
    assert_equal '[FILTERED]', details[:error]
    assert_equal '[FILTERED]', details[:userCustomData]
    assert_equal '[FILTERED]', details[:tags]
    assert_equal '[FILTERED]', details[:request]
  end

  def test_filter_payload_with_whitelist_never_filters_client
    Raygun.configuration.filter_payload_with_whitelist = true

    e = TestException.new("A test message")
    e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                       "/another/path/foo.rb:1234:in `block (3 levels) run'"])

    client_details = @client.send(:client_details)

    assert_equal client_details, @client.send(:build_payload_hash, e)[:details][:client]
  end

  def test_filter_payload_with_whitelist_never_filters_toplevel
    Timecop.freeze do
      Raygun.configuration.filter_payload_with_whitelist = true

      e = TestException.new("A test message")
      e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                        "/another/path/foo.rb:1234:in `block (3 levels) run'"])

      client_details = @client.send(:client_details)

      assert_equal Time.now.utc.iso8601, @client.send(:build_payload_hash, e)[:occurredOn]
      assert_equal Hash, @client.send(:build_payload_hash, e)[:details].class
    end
  end

  def test_filter_payload_with_whitelist_exclude_error
    Raygun.configuration.filter_payload_with_whitelist = true
    Raygun.configuration.filter_parameters = ['error', 'className', 'message', 'stackTrace']

    e = TestException.new("A test message")
    e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                       "/another/path/foo.rb:1234:in `block (3 levels) run'"])

    details = @client.send(:build_payload_hash, e)[:details]

    expected_hash = {
      className: "ClientTest::TestException",
      message:   e.message,
      stackTrace: [
        { lineNumber: "[FILTERED]",  fileName: "[FILTERED]", methodName: "[FILTERED]" },
        { lineNumber: "[FILTERED]", fileName: "[FILTERED]",      methodName: "[FILTERED]" }
      ]
    }

    assert_equal expected_hash, details[:error]
  end

  def test_filter_payload_with_whitelist_exclude_error_and_all_stacktrace_keys
    Raygun.configuration.filter_payload_with_whitelist = true
    Raygun.configuration.filter_parameters = ['error', 'className', 'message', 'stackTrace', 'lineNumber', 'fileName', 'methodName']

    e = TestException.new("A test message")
    e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                       "/another/path/foo.rb:1234:in `block (3 levels) run'"])

    details = @client.send(:build_payload_hash, e)[:details]

    expected_hash = {
      className: "ClientTest::TestException",
      message:   e.message,
      stackTrace: [
        { lineNumber: "123",  fileName: "/some/folder/some_file.rb", methodName: "some_method_name" },
        { lineNumber: "1234", fileName: "/another/path/foo.rb",      methodName: "block (3 levels) run" }
      ]
    }

    assert_equal expected_hash, details[:error]
  end

  def test_filter_payload_with_whitelist_exclude_error_and_stacktrace_keys_exception_filename
    Raygun.configuration.filter_payload_with_whitelist = true
    Raygun.configuration.filter_parameters = ['error', 'className', 'message', 'stackTrace', 'lineNumber', 'methodName']

    e = TestException.new("A test message")
    e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                       "/another/path/foo.rb:1234:in `block (3 levels) run'"])

    details = @client.send(:build_payload_hash, e)[:details]

    expected_hash = {
      className: "ClientTest::TestException",
      message:   e.message,
      stackTrace: [
        { lineNumber: "123",  fileName: "[FILTERED]", methodName: "some_method_name" },
        { lineNumber: "1234", fileName: "[FILTERED]", methodName: "block (3 levels) run" }
      ]
    }

    assert_equal expected_hash, details[:error]
  end

  def test_filter_payload_with_whitelist_exclude_error_except_stacktrace
    Raygun.configuration.filter_payload_with_whitelist = true
    Raygun.configuration.filter_parameters = ['error', 'className', 'message']

    e = TestException.new("A test message")
    e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                       "/another/path/foo.rb:1234:in `block (3 levels) run'"])

    whitelisted_hash =
    {
      :className=>"ClientTest::TestException",
      :message=>"A test message", 
      :stackTrace=>"[FILTERED]"
    }

    details = @client.send(:build_payload_hash, e)[:details]
    assert_equal whitelisted_hash, details[:error]
  end

  private

    def sample_env_hash
      {
        "SERVER_NAME"=>"localhost",
        "REQUEST_METHOD"=>"POST",
        "REQUEST_PATH"=>"/",
        "PATH_INFO"=>"/",
        "QUERY_STRING"=>"",
        "REQUEST_URI"=>"/",
        "HTTP_VERSION"=>"HTTP/1.1",
        "HTTP_HOST"=>"localhost:3000",
        "HTTP_CONNECTION"=>"keep-alive",
        "HTTP_CACHE_CONTROL"=>"max-age=0",
        "HTTP_ACCEPT"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.22 Safari/537.36",
        "HTTP_ACCEPT_ENCODING"=>"gzip,deflate,sdch",
        "HTTP_ACCEPT_LANGUAGE"=>"en-US,en;q=0.8",
        "HTTP_COOKIE"=>"cookieval",
        "GATEWAY_INTERFACE"=>"CGI/1.2",
        "SERVER_PORT"=>"3000",
        "SERVER_PROTOCOL"=>"HTTP/1.1",
        "SCRIPT_NAME"=>"",
        "REMOTE_ADDR"=>"127.0.0.1"
      }
    end

end
