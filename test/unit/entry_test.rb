# -*- coding: utf-8 -*-
require_relative "../test_helper.rb"
require 'stringio'

class EntryTest < Raygun::UnitTest

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
    fake_successful_entry
  end

  def test_error_details
    e = TestException.new("A test message")
    e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                     "/another/path/foo.rb:1234:in `block (3 levels) run'"])
    entry = Raygun::Entry.new(e, {})

    expected_hash = {
      className: "EntryTest::TestException",
      message:   e.message,
      stackTrace: [
        { lineNumber: "123",  fileName: "/some/folder/some_file.rb", methodName: "some_method_name" },
        { lineNumber: "1234", fileName: "/another/path/foo.rb",      methodName: "block (3 levels) run"}
      ]
    }

    assert_equal expected_hash, entry.send(:error_details)
  end

  def test_client_details
    expected_hash = {
      name:      Raygun::CLIENT_NAME,
      version:   Raygun::VERSION,
      clientUrl: Raygun::CLIENT_URL
    }
    entry = Raygun::Entry.new(test_exception, {})

    assert_equal expected_hash, entry.send(:client_details)
  end

  def test_version
    Raygun.setup do |config|
      config.version = 123
    end

    entry = Raygun::Entry.new(test_exception, {})

    assert_equal 123, entry.send(:version)
  end

  def test_affected_user
    e             = TestException.new("A test message")
    test_env      = { "raygun.affected_user" => { :identifier => "somepooruser@yourapp.com" },
                      "rack.input" => "" }
    entry = Raygun::Entry.new(e, test_env)
    expected_hash = test_env["raygun.affected_user"]


    assert_equal expected_hash, entry.payload[:details][:user]
  end

  def test_hostname
    entry = Raygun::Entry.new(test_exception, {})
    assert_equal Socket.gethostname, entry.send(:hostname)
  end

  def test_backtrace_without_method_name
    entry = Raygun::Entry.new(test_exception, {})

    expected = {
      lineNumber: "123",
      fileName:   "/some/folder/some_file.rb",
      methodName: "(none)"
    }

    # note lack of "in method name" in this stack trace line
    assert_equal expected, entry.send(:stack_trace_for, "/some/folder/some_file.rb:123")
  end

  def test_full_payload_hash
    Timecop.freeze do
      Raygun.configuration.version = 123
      e = TestException.new("A test message")
      e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                       "/another/path/foo.rb:1234:in `block (3 levels) run'"])

      entry = Raygun::Entry.new(e, {})

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
            className: "EntryTest::TestException",
            message:   e.message,
            stackTrace: [
              { lineNumber: "123",  fileName: "/some/folder/some_file.rb", methodName: "some_method_name" },
              { lineNumber: "1234", fileName: "/another/path/foo.rb",      methodName: "block (3 levels) run"}
            ]
          },
          userCustomData: {},
          tags:           ["test"],
          request:        {}
        }
      }

      assert_equal expected_hash, entry.payload
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
      "REMOTE_ADDR"=>"127.0.0.1",
      "rack.input" => ""
    }

    entry = Raygun::Entry.new(test_exception, sample_env_hash)

    expected_hash = {
      hostName:    "localhost",
      url:         "/",
      httpMethod:  "GET",
      iPAddress:   "127.0.0.1",
      queryString: { "a" => "b", "c" => "4945438" },
      form:        {"a"=>"b", "c"=>"4945438"},
      headers:     { "Version"=>"HTTP/1.1", "Host"=>"localhost:3000", "Connection"=>"keep-alive", "Cache-Control"=>"max-age=0", "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "User-Agent"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.22 Safari/537.36", "Accept-Encoding"=>"gzip,deflate,sdch", "Accept-Language"=>"en-US,en;q=0.8", "Cookie"=>"cookieval" },
      rawData:     {}
    }

    assert_equal expected_hash, entry.send(:request_information)
  end

  def test_getting_request_information_with_nil_env
    entry = Raygun::Entry.new(test_exception, nil)
    assert_equal({}, entry.send(:request_information))
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
      "action_dispatch.request.parameters"=> { "a" => "b", "c" => "4945438", "password" => "swordfish" },
      "rack.input" => ""
    }
    entry = Raygun::Entry.new(test_exception, put_body_env_hash)

    expected_form_hash = { "a" => "b", "c" => "4945438", "password" => "[FILTERED]" }

    assert_equal expected_form_hash, entry.send(:request_information)[:form]
  end

  def test_filtering_parameters
    post_body_env_hash = {
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
      "REMOTE_ADDR"=>"127.0.0.1",
      "rack.input"=>StringIO.new("a=b&c=4945438&password=swordfish")
    }
    entry = Raygun::Entry.new(test_exception, post_body_env_hash)

    expected_form_hash = { "a" => "b", "c" => "4945438", "password" => "[FILTERED]" }

    assert_equal expected_form_hash, entry.send(:request_information)[:form]
  end

  def test_filtering_nested_params
    post_body_env_hash = {
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
      "REMOTE_ADDR"=>"127.0.0.1",
      "rack.input"=>StringIO.new("a=b&bank%5Bcredit_card%5D%5Bcard_number%5D=my_secret_bank_number&bank%5Bname%5D=something&c=123456&user%5Bpassword%5D=my_fancy_password")
    }
    entry = Raygun::Entry.new(test_exception, post_body_env_hash)

    expected_form_hash = { "a" => "b", "bank" => { "credit_card" => { "card_number" => "[FILTERED]" }, "name" => "something" }, "c" => "123456", "user" => { "password" => "[FILTERED]" } }

    assert_equal expected_form_hash, entry.send(:request_information)[:form]
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
      "action_dispatch.remote_ip"=> "123.456.789.012",
      "rack.input" => ""
    }
    entry = Raygun::Entry.new(test_exception, sample_env_hash)

    assert_equal "123.456.789.012", entry.send(:ip_address)
    assert_equal "123.456.789.012", entry.send(:request_information)[:iPAddress]
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
      "action_dispatch.remote_ip"=> old_action_dispatch_ip,
      "rack.input" => ""
    }
    entry = Raygun::Entry.new(test_exception, sample_env_hash)

    assert_equal old_action_dispatch_ip, entry.send(:ip_address)
    assert_equal "123.456.789.012", entry.send(:request_information)[:iPAddress]
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
      "raygun.remote_ip"=>"123.456.789.012",
      "rack.input" => ""
    }
    entry = Raygun::Entry.new(test_exception, sample_env_hash)

    assert_equal "123.456.789.012", entry.send(:ip_address)
    assert_equal "123.456.789.012", entry.send(:request_information)[:iPAddress]
  end

end
