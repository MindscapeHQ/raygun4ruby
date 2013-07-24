require "rubygems"
require "bundler"
Bundler.setup(:default)

require "httparty"
require "logger"
require "json"
require "socket"
require "rack"
require "active_support/core_ext"

require "raygun/version"
require "raygun/configuration"
require "raygun/client"
require "raygun/rack_exception_interceptor"
require "raygun/railtie" if defined?(Rails)

module Raygun

  # used to identify ourselves to Raygun
  CLIENT_URL  = "https://github.com/MindscapeHQ/raygun4ruby"
  CLIENT_NAME = "Raygun4Ruby Gem"

  class << self

    # Configuration Object (instance of Raygun::Configuration)
    attr_writer :configuration

    def setup
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def track_exception(*args)
      Client.new.track_exception(*args)
    rescue Exception => e
      failsafe_log("Problem reporting exception to Raygun: #{e.class}: #{e.message}\n\n#{e.backrace.join("\n")}")
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
      configuration.failsafe_logger.info(message) if configuration.failsafe_logger
    end

  end
end
