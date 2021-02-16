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
      user = affected_user(context_hash)
      data =  {
        custom_data: {
          sidekiq_context: context_hash
        },
        tags: ['sidekiq']
      }
      if correlation_id = exception.instance_variable_get(:@__raygun_correlation_id)
        data.merge!(correlation_id: correlation_id)
      end
      ::Raygun.track_exception(
          exception,
          data,
          user
        )
    end

    # Extracts affected user information out of a Sidekiq worker class
    def self.affected_user(context_hash)
      job = context_hash[:job]

      return if job.nil? || job['class'].nil? || !Module.const_defined?(job['class'])

      worker_class = Module.const_get(job['class'])
      affected_user_method = Raygun.configuration.affected_user_method

      return if worker_class.nil? || !worker_class.respond_to?(affected_user_method)

      worker_class.send(affected_user_method, job['args'])
    rescue => e
      return unless Raygun.configuration.failsafe_logger

      failsafe_log("Problem in sidekiq affected user tracking: #{e.class}: #{e.message}\n\n#{e.backtrace.join("\n")}")

      nil
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
