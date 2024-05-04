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

  def test_we_are_in_sidekiqs_list_of_error_handlers
    # Sidekiq 7.x stores error handlers inside a configuration object, while 6.x and below stores them directly against the Sidekiq module
    error_handlers = Sidekiq.respond_to?(:error_handlers) ? Sidekiq.error_handlers : Sidekiq.default_configuration.error_handlers

    assert error_handlers.include?(Raygun::SidekiqReporter)
  end

end
