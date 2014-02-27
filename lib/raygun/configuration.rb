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

    # Which controller method should we call to find out the affected user?
    attr_accessor :affected_user_method

    # Which methods should we try on the affected user object in order to get an identifier
    attr_accessor :affected_user_identifier_methods

    # Which parameter keys should we filter out by default?
    attr_accessor :filter_parameters

    # Exception classes to ignore by default
    IGNORE_DEFAULT = ['ActiveRecord::RecordNotFound',
                      'ActionController::RoutingError',
                      'ActionController::InvalidAuthenticityToken',
                      'CGI::Session::CookieStore::TamperedWithCookie',
                      'ActionController::UnknownAction',
                      'AbstractController::ActionNotFound',
                      'Mongoid::Errors::DocumentNotFound']

    DEFAULT_FILTER_PARAMETERS = [ :password, :card_number, :cvv ]

    def initialize
      # set default attribute values
      @ignore                           = IGNORE_DEFAULT
      @custom_data                      = {}
      @silence_reporting                = nil
      @affected_user_method             = :current_user
      @affected_user_identifier_methods = [ :email, :username, :id ]
      @filter_parameters                = DEFAULT_FILTER_PARAMETERS
    end

    def [](key)
      send(key)
    end

  end
end