require_relative "../test_helper.rb"

# Very simple test
class ResqueFailureTest < Raygun::UnitTest

  require "resque/failure/raygun"

  def setup
    super
    Raygun.configuration.send_in_background = false

    stub_request(:post, 'https://api.raygun.com/entries').to_return(status: 202)
    fake_successful_entry
  end

  def test_failure_backend_appears_to_work
    result = Resque::Failure::Raygun.new(
      StandardError.new("Worker Problem"),
      "TestWorker PID 123",
      "super_important_jobs",
      class: "SendCookies", args: [ "nik" ]
    ).save
    
    assert result && result.success?, "Expected success, got #{result.inspect}"
  end

end
