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
        }
      }
      ::Raygun.track_exception(
          exception,
          data,
          user
        )
    end

    # Adds functionality to report affected user in Sidekiq workers
    #
    # Requires the user to implement a class method in the worker that returns affected_user as an object.
    # This method has the same name as the one defined in their config.affected_user_method.
    #
    # If they don't have config.affected_user_method defined, they should implement a class method `current_user`
    # that returns a user object based on the arguments orginially pased to the worker.
    #
    # Their affected_user_method should take the original worker arguments as an array
    def self.affected_user(context_hash)
      job = context_hash[:job]

      if !job.nil?
        affected_user_method = Raygun.configuration.affected_user_method
        worker_class = Module.const_get(job['class']) unless job['class'].nil?
        args = job['args'] unless job['args'].nil?

        if worker_class.respond_to?(affected_user_method)
          begin
            worker_class.send(affected_user_method, args)
          rescue => e
            # swallow all exceptions since `affected_user` is non-critical info
            if Raygun.configuration.failsafe_logger
              failsafe_log("Problem in #{affected_user_method}: #{e.class}: #{e.message}\n\n#{e.backtrace.join("\n")}")
            end
            nil
          end
        end

      end

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
