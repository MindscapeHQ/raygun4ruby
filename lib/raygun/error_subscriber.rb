# Subscribes to errors using Rails' error reporting API
# https://edgeguides.rubyonrails.org/error_reporting.html
class Raygun::ErrorSubscriber
  def report(error, handled:, severity:, context:, source: nil)
    tags = context.delete(:tags) if context.is_a?(Hash)

    data = {
      custom_data: {
        "rails.error": {
          handled: handled,
          severity: severity,
          context: context,
          source: source
        },
      },
      tags: ["rails_error_reporter", *tags].compact
    }

    if source == "job.sidekiq" && defined?(Sidekiq)
      Raygun::SidekiqReporter.call(error, data)
    else
      Raygun.track_exception(error, data)
    end
  end
end