require_relative "../test_helper.rb"

# Very simple test
class ResqueFailureTest < Raygun::UnitTest

  require "resque/failure/raygun"

  def setup
    super
    fake_successful_entry
  end

  def test_failure_backend_appears_to_work
    assert Resque::Failure::Raygun.new(
      StandardError.new("Worker Problem"),
      "TestWorker PID 123",
      "super_important_jobs",
      class: "SendCookies", args: [ "nik" ]
    ).save.success?
  end

end