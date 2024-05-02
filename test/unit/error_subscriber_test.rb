require_relative "../test_helper.rb"

class ErrorSubscriberTest < Raygun::UnitTest

  def test_tracking_exception_via_subscriber
    body_matcher = lambda do |body|
      json = JSON.parse(body)
      details = json["details"]

      details["userCustomData"] && 
        details["userCustomData"]["rails.error"] &&
        details["userCustomData"]["rails.error"]["handled"] == true &&
        details["tags"] == ["rails_error_reporter", "test_tag", "test"]
    end

    request_stub = stub_request(:post, 'https://api.raygun.com/entries')
      .with(
        body: body_matcher
      )
      .to_return(status: 202).times(1)

    Raygun::ErrorSubscriber.new.report(
      StandardError.new("test error"),
      handled: true,
      severity: "warning",
      context: {
        tags: ["test_tag"]
      },
      source: "application"
    )

    Raygun.wait_for_futures
    assert_requested request_stub
  end

end