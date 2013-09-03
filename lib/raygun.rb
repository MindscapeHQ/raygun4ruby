require "bundler"
Bundler.setup(:default)

require "httparty"
require "logger"
require "json"
require "socket"
require "rack"

require "raygun/version"
require "raygun/configuration"
require "raygun/client"
require "raygun/rack_exception_interceptor"
require "raygun/testable"
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
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def track_exception(exception_instance, env = {})
      if should_report?(exception_instance)
        log("[Raygun] Tracking Exception...")
        Client.new.track_exception(exception_instance, env)
      end
    rescue Exception => e
      if configuration.failsafe_logger
        failsafe_log("Problem reporting exception to Raygun: #{e.class}: #{e.message}\n\n#{e.backrace.join("\n")}")
      else
        raise e
      end
    end

    def track_exceptions
      yield
    rescue => e
      track_exception(e)
    end

    def log(message)
      configuration.logger.info(message) if configuration.logger
    end

    def failsafe_log(message)
      configuration.failsafe_logger.info(message)
    end

    private

      def should_report?(exception)
        return false if configuration.silence_reporting
        return false if configuration.ignore.include?(exception.class.to_s)
        true
      end

  end
end
