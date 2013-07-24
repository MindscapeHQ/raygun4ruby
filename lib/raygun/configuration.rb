module Raygun
  class Configuration

    # Your Raygun API Key - this can be found on your dashboard at Raygun.io
    attr_accessor :api_key

    # Array of exception classes to ignore
    attr_accessor :ignore

    # Version to use
    attr_accessor :version

    # Custom Data to send with each exception
    attr_accessor :custom_data

    # Logger to use when if we find an exception :)
    attr_accessor :logger

    # Should we silence exception reporting (e.g in Development environments)
    attr_accessor :silence_reporting

    # Failsafe logger (for exceptions that happen when we're attempting to report exceptions)
    attr_accessor :failsafe_logger

    # Exception classes to ignore by default
    IGNORE_DEFAULT = ['ActiveRecord::RecordNotFound',
                      'ActionController::RoutingError',
                      'ActionController::InvalidAuthenticityToken',
                      'CGI::Session::CookieStore::TamperedWithCookie',
                      'ActionController::UnknownAction',
                      'AbstractController::ActionNotFound',
                      'Mongoid::Errors::DocumentNotFound']

    def initialize
      # set default attribute values
      @ignore      = IGNORE_DEFAULT
      @custom_data = {}
    end

    def [](key)
      send(key)
    end

  end
end