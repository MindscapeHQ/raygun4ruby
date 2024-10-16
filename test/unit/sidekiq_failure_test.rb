require_relative "../test_helper.rb"

require "sidekiq"

# Convince Sidekiq it's on a server :)
module Sidekiq
  class << self
    undef server?
    def server?
      true
    end
  end
end
require "raygun/sidekiq"

class SidekiqFailureTest < Raygun::UnitTest

  def setup
    require "sidekiq/job_retry"

    super
    Raygun.configuration.send_in_background = false

    stub_request(:post, 'https://api.raygun.com/entries').to_return(status: 202)
    fake_successful_entry
  end

  def test_failure_backend_appears_to_work
    response = Raygun::SidekiqReporter.call(
      StandardError.new("Oh no! Your Sidekiq has failed!"),
      { sidekick_name: "robin" }, 
      {} # config
    )

    assert response && response.success?, "Expected success, got #{response.class}: #{response.inspect}"
  end

  def test_failure_backend_unwraps_retries
    WebMock.reset!

    unwrapped_stub = stub_request(:post, 'https://api.raygun.com/entries').
      with(body: /StandardError/).
      to_return(status: 202)

    begin
      raise StandardError.new("Some job in Sidekiq failed, oh dear!")
    rescue
      raise Sidekiq::JobRetry::Handled
    end

  rescue Sidekiq::JobRetry::Handled => e

    response = Raygun::SidekiqReporter.call(
      e,
      { sidekick_name: "robin" }, 
      {} # config
    )

    assert_requested unwrapped_stub
    assert response && response.success?, "Expected success, got #{response.class}: #{response.inspect}"
  end

  def test_failured_backend_ignores_retries_if_configured
    Raygun.configuration.track_retried_sidekiq_jobs = false
    
    begin
      raise StandardError.new("Some job in Sidekiq failed, oh dear!")
    rescue
      raise Sidekiq::JobRetry::Handled
    end

  rescue Sidekiq::JobRetry::Handled => e

    refute Raygun::SidekiqReporter.call(e,
      { sidekick_name: "robin" }, 
      {} # config
    )
  ensure
    Raygun.configuration.track_retried_sidekiq_jobs = true
  end

  # See https://github.com/MindscapeHQ/raygun4ruby/issues/183
  # (This is how Sidekiq pre 7.1.5 calls error handlers: https://github.com/sidekiq/sidekiq/blob/1ba89bbb22d2fd574b11702d8b6ed63ae59e2256/lib/sidekiq/config.rb#L269)
  def test_failure_backend_appears_to_work_without_config_argument
    response = Raygun::SidekiqReporter.call(
      StandardError.new("Oh no! Your Sidekiq has failed!"),
      { sidekick_name: "robin" }
    )

    assert response && response.success?, "Expected success, got #{response.class}: #{response.inspect}"
  end

  def test_we_are_in_sidekiqs_list_of_error_handlers
    # Sidekiq 7.x stores error handlers inside a configuration object, while 6.x and below stores them directly against the Sidekiq module
    error_handlers = Sidekiq.respond_to?(:error_handlers) ? Sidekiq.error_handlers : Sidekiq.default_configuration.error_handlers

    assert error_handlers.include?(Raygun::SidekiqReporter)
  end

  def test_rails_error_reporter_uses_sidekiq_reporter
    WebMock.reset!

    tagged_request = stub_request(:post, 'https://api.raygun.com/entries').
      with(body: /"sidekiq"/). # should have a sidekiq tag!
      to_return(status: 202)

    error = StandardError.new("Oh no! Your Sidekiq has failed!")

    response = Raygun::ErrorSubscriber.new.report(
      error,
      handled: true,
      severity: "error",
      context: { sidekick_name: "robin" },
      source: "job.sidekiq"
    )

    assert response && response.success?, "Expected success, got #{response.class}: #{response.inspect}"

    assert_requested tagged_request
  end

end
