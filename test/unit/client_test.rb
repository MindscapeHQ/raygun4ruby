require_relative "../test_helper.rb"

class ClientTest < Raygun::UnitTest

  class TestException < StandardError; end

  def setup
    super
    @client = Raygun::Client.new
    fake_successful_entry
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

  def test_hostname
    assert_equal Socket.gethostname, @client.send(:hostname)
  end

  def test_full_payload_hash
    Timecop.freeze do
      Raygun.configuration.version = 123
      e = TestException.new("A test message")
      e.set_backtrace(["/some/folder/some_file.rb:123:in `some_method_name'",
                       "/another/path/foo.rb:1234:in `block (3 levels) run'"])

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
          request:        {}
        }
      }

      assert_equal expected_hash, @client.send(:build_payload_hash, e, nil)
    end
  end

end
