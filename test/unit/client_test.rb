# -*- coding: utf-8 -*-
require_relative "../test_helper.rb"
require 'stringio'

class ClientTest < Raygun::UnitTest

  class TestException < StandardError
    def initialize(message = nil)
      super(message || "A test message")
    end
  end

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

    # Force NZ time zone for utcOffset tests
    ENV['TZ'] = 'UTC-13'
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
    assert_equal exception_hash, @client.send(:error_details, test_exception)
  end

  def test_error_details_with_nil_message
    e = NilMessageError.new
    expected_message = ""
    assert_equal expected_message, @client.send(:error_details, e)[:message]
  end

  def test_utc_offset
    expected = 13

    assert_equal expected, @client.send(:build_payload_hash, test_exception, sample_env_hash)[:details][:environment][:utcOffset]
  end

  def test_inner_error_details
    oe = TestException.new("A test message")
    oe.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'"])

    ie = TestException.new("Inner test message")
    ie.set_backtrace(["/another/path/foo.rb:1234:in `block (3 levels) run'"])

    e = nest_exceptions(oe, ie)

    expected_hash = {
      className: "ClientTest::TestException",
      message:   oe.message,
      stackTrace: [
        { lineNumber: "123",  fileName: "/some/folder/some_file.rb", methodName: "some_method_name" }
      ]
    }

    # test inner error according with its availability (ruby >= 2.1)
    if e.respond_to? :cause
      expected_hash[:innerError] = {
        className: "ClientTest::TestException",
        message:   ie.message,
        stackTrace: [
          { lineNumber: "1234", fileName: "/another/path/foo.rb",      methodName: "block (3 levels) run"}
        ]
      }
    end

    assert_equal expected_hash, @client.send(:error_details, e)
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
    test_env      = { "raygun.affected_user" => { :identifier => "somepooruser@yourapp.com" } }
    expected_hash = test_env["raygun.affected_user"]

    assert_equal expected_hash, @client.send(:build_payload_hash, test_exception, test_env)[:details][:user]
  end

  def test_tags
    configuration_tags = %w{alpha beta gaga}
    explicit_env_tags  = %w{one two three four}
    rack_env_tag       = %w{test}

    Raygun.setup do |config|
      config.tags = configuration_tags
    end

    test_env      = { tags: explicit_env_tags }
    expected_tags =  configuration_tags + explicit_env_tags + rack_env_tag

    assert_equal expected_tags, @client.send(:build_payload_hash, test_exception, test_env)[:details][:tags]
  end

  def test_hostname
    assert_equal Socket.gethostname, @client.send(:hostname)
  end

  def test_unicode
    e = TestException.new('日本語のメッセージ です')

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
          error: exception_hash,
          userCustomData: {},
          tags:           ["test"],
          request:        {},
          groupingKey:    grouping_key,
          environment: {
            utcOffset: 13
          }
        }
      }

      assert_equal expected_hash, @client.send(:build_payload_hash, test_exception, { grouping_key: grouping_key })
    end
  end

  def test_getting_request_information
    env_hash = sample_env_hash.merge({
      "QUERY_STRING"=>"a=b&c=4945438",
      "REQUEST_URI"=>"/?a=b&c=4945438",
    })

    expected_hash = {
      hostName:    "localhost",
      url:         "/",
      httpMethod:  "GET",
      iPAddress:   "127.0.0.1",
      queryString: { "a" => "b", "c" => "4945438" },
      headers:     { "Version"=>"HTTP/1.1", "Host"=>"localhost:3000", "Cookie"=>"cookieval" },
      form:        {},
      rawData:     {}
    }

    assert_equal expected_hash, @client.send(:request_information, env_hash)
  end

  def test_getting_request_information_with_nil_env
    assert_equal({}, @client.send(:request_information, nil))
  end

  def test_non_form_parameters
    put_body_env_hash = sample_env_hash.merge({
      "REQUEST_METHOD"=>"PUT",
      "action_dispatch.request.parameters"=> { "a" => "b", "c" => "4945438", "password" => "swordfish" }
    })

    expected_form_hash = { "a" => "b", "c" => "4945438", "password" => "[FILTERED]" }

    assert_equal expected_form_hash, @client.send(:request_information, put_body_env_hash)[:rawData]
  end

  def test_error_raygun_custom_data
    custom_data = { "kappa" => "keepo" }
    e           = Raygun::Error.new("A test message", custom_data)
    test_env    = {}
    expected_form_hash = test_env.merge(custom_data)

    assert_equal expected_form_hash, @client.send(:build_payload_hash, e, test_env)[:details][:userCustomData]
  end

  def test_custom_data_configuration_with_hash
    custom_data = {foo: '123'}
    Raygun.configuration.custom_data = custom_data

    assert_equal custom_data, @client.send(:build_payload_hash, test_exception, sample_env_hash)[:details][:userCustomData]
  end

  def test_custom_data_configuration_with_proc
    Raygun.configuration.custom_data do |exception, env|
      {exception_message: exception.message, server_name: env["SERVER_NAME"]}
    end
    expected = {
      exception_message: "A test message",
      server_name: "localhost"
    }

    assert_equal expected, @client.send(:build_payload_hash, test_exception, sample_env_hash)[:details][:userCustomData]
  end

  def test_filtering_parameters
    post_body_env_hash = sample_env_hash.merge(
      "REQUEST_METHOD" => "POST",
      "rack.input"=>StringIO.new("a=b&c=4945438&password=swordfish")
    )

    expected_form_hash = { "a" => "b", "c" => "4945438", "password" => "[FILTERED]" }

    assert_equal expected_form_hash, @client.send(:request_information, post_body_env_hash)[:form]
  end

  def test_filtering_nested_params
    post_body_env_hash = sample_env_hash.merge(
      "REQUEST_METHOD" => "POST",
      "rack.input" => StringIO.new("a=b&bank%5Bcredit_card%5D%5Bcard_number%5D=my_secret_bank_number&bank%5Bname%5D=something&c=123456&user%5Bpassword%5D=my_fancy_password")
    )

    expected_form_hash = { "a" => "b", "bank" => { "credit_card" => { "card_number" => "[FILTERED]" }, "name" => "something" }, "c" => "123456", "user" => { "password" => "[FILTERED]" } }

    assert_equal expected_form_hash, @client.send(:request_information, post_body_env_hash)[:form]
  end

  def test_filter_parameters_using_proc
    # filter any parameters that start with "nsa_only"
    Raygun.configuration.filter_parameters do |hash|
      hash.inject({}) do |sanitized_hash, (k, v)|
        sanitized_hash[k] = if k.start_with? "nsa_only"
                              "[OUREYESONLY]"
                            else
                              v
                            end
        sanitized_hash
      end
    end

    post_body_env_hash = sample_env_hash.merge(
      "REQUEST_METHOD" => "POST",
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
      "REQUEST_METHOD" => "POST",
      "rack.input" => StringIO.new(URI.encode_www_form(parameters))
    )

    assert_equal expected_form_hash, @client.send(:request_information, post_body_env_hash)[:form]
  ensure
    Raygun.configuration.filter_parameters = nil
  end

  def test_ip_address_from_action_dispatch
    env_hash = sample_env_hash.merge({
      "action_dispatch.remote_ip"=> "123.456.789.012"
    })

    assert_equal "123.456.789.012", @client.send(:ip_address_from, env_hash)
    assert_equal "123.456.789.012", @client.send(:request_information, env_hash)[:iPAddress]
  end

  def test_ip_address_from_old_action_dispatch
    old_action_dispatch_ip = FakeActionDispatcherIp.new("123.456.789.012")
    env_hash = sample_env_hash.merge({
      "action_dispatch.remote_ip"=> old_action_dispatch_ip
    })

    assert_equal old_action_dispatch_ip, @client.send(:ip_address_from, env_hash)
    assert_equal "123.456.789.012", @client.send(:request_information, env_hash)[:iPAddress]
  end

  def test_ip_address_from_raygun_specific_key
    env_hash = sample_env_hash.merge({
      "raygun.remote_ip"=>"123.456.789.012"
    })

    assert_equal "123.456.789.012", @client.send(:ip_address_from, env_hash)
    assert_equal "123.456.789.012", @client.send(:request_information, env_hash)[:iPAddress]
  end

  def test_ip_address_returns_not_available_if_not_set
    env_hash = sample_env_hash.dup
    env_hash.delete("REMOTE_ADDR")

    assert_equal "(Not Available)", @client.send(:ip_address_from, env_hash)
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

  def test_filter_payload_with_whitelist_never_filters_toplevel
    Timecop.freeze do
      Raygun.configuration.filter_payload_with_whitelist = true
      Raygun.configuration.whitelist_payload_shape = {}

      e = test_exception

      assert_equal Time.now.utc.iso8601, @client.send(:build_payload_hash, e)[:occurredOn]
      assert_equal Hash, @client.send(:build_payload_hash, e)[:details].class
    end
  end

  def test_filter_payload_with_whitelist_never_filters_client
    Raygun.configuration.filter_payload_with_whitelist = true
    Raygun.configuration.whitelist_payload_shape = {}

    client_details = @client.send(:client_details)

    assert_equal client_details, @client.send(:build_payload_hash, test_exception)[:details][:client]
  end

  def test_filter_payload_with_whitelist_default_error
    Raygun.configuration.filter_payload_with_whitelist = true

    details = @client.send(:build_payload_hash, test_exception)[:details]

    assert_equal exception_hash, details[:error]
  end

  def test_filter_payload_with_whitelist_exclude_error_keys
    Raygun.configuration.filter_payload_with_whitelist = true
    Raygun.configuration.whitelist_payload_shape = {
      error: {
        className: true,
        message: true,
        stackTrace: true
      }
    }

    details = @client.send(:build_payload_hash, test_exception)[:details]

    assert_equal exception_hash, details[:error]
  end

  def test_filter_payload_with_whitelist_exclude_error_except_stacktrace
    Raygun.configuration.filter_payload_with_whitelist = true
    Raygun.configuration.whitelist_payload_shape = {
      error: {
        className: true,
        message: true,
      }
    }

    details = @client.send(:build_payload_hash, test_exception)[:details]

    expected_hash = exception_hash.merge({
      stackTrace: "[FILTERED]"
    })

    assert_equal expected_hash, details[:error]
  end

  def test_filter_payload_with_whitelist_proc
    Raygun.configuration.filter_payload_with_whitelist = true
    Raygun.configuration.whitelist_payload_shape do |payload|
      payload
    end

    details = @client.send(:build_payload_hash, test_exception)[:details]

    assert_equal exception_hash, details[:error]
  end

  def test_filter_payload_with_whitelist_default_request_post
    Raygun.configuration.filter_payload_with_whitelist = true

    post_body_env_hash = sample_env_hash.merge(
      "REQUEST_METHOD" => "POST",
      "rack.input"=>StringIO.new("a=b&c=4945438&password=swordfish")
    )

    details = @client.send(:build_payload_hash, test_exception, post_body_env_hash)[:details]

    expected_hash = {
      hostName:    "localhost",
      url:         "/",
      httpMethod:  "POST",
      iPAddress:   "127.0.0.1",
      queryString: { },
      headers:     { "Version"=>"HTTP/1.1", "Host"=>"localhost:3000", "Cookie"=>"cookieval" },
      form:        { "a" => "[FILTERED]", "c" => "[FILTERED]", "password" => "[FILTERED]" },
      rawData:     nil
    }

    assert_equal expected_hash, details[:request]
  end

  def test_filter_payload_with_whitelist_request_post_except_formkey
    Raygun.configuration.filter_payload_with_whitelist = true
    shape = Raygun.configuration.whitelist_payload_shape.dup
    shape[:request] = Raygun.configuration.whitelist_payload_shape[:request].merge(
      form: {
        username: true
      }
    )
    Raygun.configuration.whitelist_payload_shape = shape

    post_body_env_hash = sample_env_hash.merge(
      "REQUEST_METHOD" => "POST",
      "rack.input"=>StringIO.new("username=foo&password=swordfish")
    )

    details = @client.send(:build_payload_hash, test_exception, post_body_env_hash)[:details]

    expected_hash = {
      hostName:    "localhost",
      url:         "/",
      httpMethod:  "POST",
      iPAddress:   "127.0.0.1",
      queryString: { },
      headers:     { "Version"=>"HTTP/1.1", "Host"=>"localhost:3000", "Cookie"=>"cookieval" },
      form:        { "username" => "foo", "password" => "[FILTERED]" },
      rawData:     nil
    }

    assert_equal expected_hash, details[:request]
  end

  def test_filter_payload_with_whitelist_default_request_get
    Raygun.configuration.filter_payload_with_whitelist = true

    env_hash = sample_env_hash.merge({
      "QUERY_STRING"=>"a=b&c=4945438",
      "REQUEST_URI"=>"/?a=b&c=4945438",
    })
    expected_hash = {
      hostName:    "localhost",
      url:         "/",
      httpMethod:  "GET",
      iPAddress:   "127.0.0.1",
      queryString: { "a" => "b", "c" => "4945438" },
      headers:     { "Version"=>"HTTP/1.1", "Host"=>"localhost:3000", "Cookie"=>"cookieval" },
      form:        {},
      rawData:     {}
    }

    details = @client.send(:build_payload_hash, test_exception, env_hash)[:details]

    assert_equal expected_hash, details[:request]
  end

  def test_filter_payload_with_whitelist_default_request_get_except_querystring
    Raygun.configuration.filter_payload_with_whitelist = true
    shape = Raygun.configuration.whitelist_payload_shape.dup
    shape[:request] = Raygun::Configuration::DEFAULT_WHITELIST_PAYLOAD_SHAPE_REQUEST.dup.tap do |h|
      h.delete(:queryString)
    end
    Raygun.configuration.whitelist_payload_shape = shape

    expected_hash = {
      hostName:    "localhost",
      url:         "/",
      httpMethod:  "GET",
      iPAddress:   "127.0.0.1",
      queryString: "[FILTERED]",
      headers:     { "Version"=>"HTTP/1.1", "Host"=>"localhost:3000", "Cookie"=>"cookieval" },
      form:        {},
      rawData:     {}
    }

    details = @client.send(:build_payload_hash, test_exception, sample_env_hash)[:details]

    assert_equal expected_hash, details[:request]
  end

  def test_filter_payload_with_whitelist_being_false_does_not_filter_query_string
    Raygun.configuration.filter_payload_with_whitelist = false

    env_hash = sample_env_hash.merge({
      "QUERY_STRING"=>"a=b&c=4945438",
      "REQUEST_URI"=>"/?a=b&c=4945438",
    })
    expected_hash = {
      hostName:    "localhost",
      url:         "/",
      httpMethod:  "GET",
      iPAddress:   "127.0.0.1",
      queryString: { "a" => "b", "c" => "4945438" },
      headers:     { "Version"=>"HTTP/1.1", "Host"=>"localhost:3000", "Cookie"=>"cookieval" },
      form:        {},
      rawData:     {}
    }

    details = @client.send(:build_payload_hash, test_exception, env_hash)[:details]

    assert_equal expected_hash, details[:request]
  end

  def test_filter_payload_with_whitelist_request_specific_keys
    Raygun.configuration.filter_payload_with_whitelist = true
    Raygun.configuration.whitelist_payload_shape = {
      request: {
        url: true,
        httpMethod: true,
        hostName: true
      }
    }

    details = @client.send(:build_payload_hash, test_exception, sample_env_hash)[:details]

    expected_hash = {
      hostName:    "localhost",
      url:         "/",
      httpMethod:  "GET",
      iPAddress:   "[FILTERED]",
      queryString: "[FILTERED]",
      headers:     "[FILTERED]",
      form:        "[FILTERED]",
      rawData:     "[FILTERED]"
    }

    assert_equal expected_hash, details[:request]
  end

  def test_build_payload_hash_adds_affected_user_details_when_supplied_with_user
    user = OpenStruct.new(id: '123', email: 'test@email.com', first_name: 'Taylor')
    expected_details = {
      :IsAnonymous => false,
      :Identifier => '123',
      :Email => 'test@email.com',
      :FirstName => 'Taylor',
    }

    user_details = @client.send(:build_payload_hash, test_exception, sample_env_hash, user)[:details][:user]

    assert_equal expected_details, user_details
  end

  private

  def test_exception
    e = TestException.new
    e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                     "/another/path/foo.rb:1234:in `block (3 levels) run'"])

    e
  end

  def nest_exceptions(outer_exception, inner_exception)
    begin
      begin
        raise inner_exception.class, inner_exception.message
      rescue => e
        e.set_backtrace inner_exception.backtrace
        raise outer_exception.class, outer_exception.message
      end
    rescue => nested_exception
      nested_exception.set_backtrace outer_exception.backtrace
    end

    nested_exception
  end

  def exception_hash
    {
      className: "ClientTest::TestException",
      message:   "A test message",
      stackTrace: [
        { lineNumber: "123",  fileName: "/some/folder/some_file.rb", methodName: "some_method_name" },
        { lineNumber: "1234", fileName: "/another/path/foo.rb",      methodName: "block (3 levels) run"}
      ]
    }
  end

  def sample_env_hash
    {
      "SERVER_NAME"=>"localhost",
      "REQUEST_METHOD"=>"GET",
      "REQUEST_PATH"=>"/",
      "PATH_INFO"=>"/",
      "QUERY_STRING"=>"",
      "REQUEST_URI"=>"/",
      "HTTP_VERSION"=>"HTTP/1.1",
      "HTTP_HOST"=>"localhost:3000",
      "HTTP_COOKIE"=>"cookieval",
      "GATEWAY_INTERFACE"=>"CGI/1.2",
      "SERVER_PORT"=>"3000",
      "SERVER_PROTOCOL"=>"HTTP/1.1",
      "SCRIPT_NAME"=>"",
      "REMOTE_ADDR"=>"127.0.0.1"
    }
  end
end
