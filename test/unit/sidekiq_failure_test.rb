require_relative "../test_helper.rb"

require "sidekiq"
# Convince Sidekiq it's on a server :)
module Sidekiq
  def self.server?
    true
  end
end
require "raygun/sidekiq"

class SidekiqFailureTest < Raygun::UnitTest

  def setup
    super
    fake_successful_entry
  end

  def test_failure_backend_appears_to_work
    assert Raygun::SidekiqReporter.call(
      StandardError.new("Oh no! Your Sidekiq has failed!"),
      sidekick_name: "robin"
    ).success?
  end

  def test_we_are_in_sidekiqs_list_of_error_handlers
    assert Sidekiq.error_handlers.include?(Raygun::SidekiqReporter)
  end

end