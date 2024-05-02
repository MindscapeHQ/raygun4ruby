# Adapted from Bugsnag code, and Sidekiq Erorr Handling instructions
#
# SideKiq: https://github.com/sidekiq/sidekiq/wiki/Error-Handling
# Bugsnag: https://github.com/bugsnag/bugsnag-ruby/blob/master/lib/bugsnag/sidekiq.rb

module Raygun

  class SidekiqReporter
    def self.call(exception, context_hash, config)
      user = affected_user(context_hash)
      data =  {
        custom_data: {
          sidekiq_context: context_hash
        },
        tags: ['sidekiq']
      }
      if exception.instance_variable_defined?(:@__raygun_correlation_id) && correlation_id = exception.instance_variable_get(:@__raygun_correlation_id)
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

Sidekiq.configure_server do |config|
  config.error_handlers << Raygun::SidekiqReporter
end
