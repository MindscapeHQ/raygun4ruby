# Adapted from Bugsnag code as per Sidekiq 2.x comment request
#
# SideKiq 2.x: https://github.com/mperham/sidekiq/blob/2-x/lib/sidekiq/exception_handler.rb
# Bugsnag: https://github.com/bugsnag/bugsnag-ruby/blob/master/lib/bugsnag/sidekiq.rb

module Raygun

  class SidekiqMiddleware  # Used for Sidekiq 2.x only
    def call(worker, message, queue)
      begin
        yield
      rescue Exception => ex
        raise ex if [Interrupt, SystemExit, SignalException].include?(ex.class)
        SidekiqReporter.call(ex, worker: worker, message: message, queue: queue)
        raise ex
      end
    end
  end

  class SidekiqReporter
    def self.call(exception, context_hash)
      ::Raygun.track_exception(exception,
          custom_data: {
            sidekiq_context: context_hash
          }
        )
    end
  end
end

if Sidekiq::VERSION < '3'
  Sidekiq.configure_server do |config|
    config.server_middleware do |chain|
      chain.add Raygun::SidekiqMiddleware
    end
  end
else
  Sidekiq.configure_server do |config|
    config.error_handlers << Raygun::SidekiqReporter
  end
end