require "rubygems"
require "bundler"
Bundler.setup(:default)

require "httparty"
require "logger"
require "json"
require "socket"
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
    end

    def track_exceptions
      yield
    rescue => e
      track_exception(e)
    end

  end
end
