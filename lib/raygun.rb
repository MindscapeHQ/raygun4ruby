require "concurrent"
require "httparty"
require "logger"
require "json"
require "socket"
require "rack"
require "ostruct"

require "raygun/version"
require "raygun/configuration"
require "raygun/client"
require "raygun/javascript_tracker"
require "raygun/middleware/rack_exception_interceptor"
require "raygun/middleware/breadcrumbs_store_initializer"
require "raygun/middleware/javascript_exception_tracking"
require "raygun/testable"
require "raygun/error"
require "raygun/affected_user"
require "raygun/services/apply_whitelist_filter_to_payload"
require "raygun/breadcrumbs/breadcrumb"
require "raygun/breadcrumbs/store"
require "raygun/breadcrumbs"
require "raygun/railtie" if defined?(Rails)

module Raygun

  # used to identify ourselves to Raygun
  CLIENT_URL  = "https://github.com/MindscapeHQ/raygun4ruby"
  CLIENT_NAME = "Raygun4Ruby Gem"

  class << self
    include Testable

    # Configuration Object (instance of Raygun::Configuration)
    attr_writer :configuration

    def setup
      yield(configuration)

      log("configuration settings: #{configuration.inspect}")
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def default_configuration
      configuration.defaults
    end

    def reset_configuration
      @configuration = Configuration.new
    end

    def configured?
      !!configuration.api_key
    end

    def track_exception(exception_instance, env = {}, user = nil, retry_count = 1)
      log('tracking exception')

      if configuration.send_in_background
        track_exception_async(exception_instance, env, user, retry_count)
      else
        track_exception_sync(exception_instance, env, user, retry_count)
      end
    end

    def track_exceptions
      yield
    rescue => e
      track_exception(e)
    end

    def record_breadcrumb(
        message: nil,
        category: '',
        level: :info,
        timestamp: Time.now.utc,
        metadata: {},
        class_name: nil,
        method_name: nil,
        line_number: nil
    )
      log('recording breadcrumb')

      Raygun::Breadcrumbs::Store.record(
        message: message,
        category: category,
        level: level,
        timestamp: timestamp,
        metadata: metadata,
        class_name: class_name,
        method_name: method_name,
        line_number: line_number,
      )
    end

    def log(message)
      return unless configuration.debug

      configuration.logger.info("[Raygun] #{message}") if configuration.logger
    end

    def failsafe_log(message)
      configuration.failsafe_logger.info(message)
    end

    def deprecation_warning(message)
      if defined?(ActiveSupport::Deprecation)
        ActiveSupport::Deprecation.warn(message)
      else
        puts message
      end
    end

    private

    def track_exception_async(*args)
      future = Concurrent::Future.execute { track_exception_sync(*args) }
      future.add_observer(lambda do |_, value, reason|
        if value == nil || !value.responds_to?(:response) || value.response.code != "202"
          log("unexpected response from Raygun, could indicate error: #{value.inspect}")
        end
      end, :call)
    end

    def track_exception_sync(exception_instance, env, user, retry_count)
      if should_report?(exception_instance)
        log('attempting to send exception')
        resp = Client.new.track_exception(exception_instance, env, user)
        log('sent payload to api')

        resp
      end
    rescue Exception => e
      log('error sending exception to raygun, see failsafe logger for more information')

      if configuration.failsafe_logger
        failsafe_log("Problem reporting exception to Raygun: #{e.class}: #{e.message}\n\n#{e.backtrace.join("\n")}")
      end

      if retry_count > 0
        new_exception = e.exception("raygun4ruby encountered an exception processing your exception")
        new_exception.set_backtrace(e.backtrace)

        env[:custom_data] ||= {}
        env[:custom_data].merge!(original_stacktrace: exception_instance.backtrace)

        ::Raygun::Breadcrumbs::Store.clear

        track_exception(new_exception, env, user, retry_count - 1)
      else
        raise e
      end
    end


    def print_api_key_warning
      $stderr.puts(NO_API_KEY_MESSAGE)
    end

    def should_report?(exception)
      if configuration.silence_reporting
        log('skipping reporting because Configuration.silence_reporting is enabled')

        return false
      end

      if configuration.ignore.flatten.include?(exception.class.to_s)
        log("skipping reporting of exception #{exception.class} because it is in the ignore list")

        return false
      end

      true
    end
  end
end
