module Raygun
  class Configuration

    def self.config_option(name)
      define_method(name) do
        read_value(name)
      end

      define_method("#{name}=") do |value|
        set_value(name, value)
      end
    end

    # Your Raygun API Key - this can be found on your dashboard at Raygun.io
    config_option :api_key

    # Array of exception classes to ignore
    config_option :ignore

    # Version to use
    config_option :version

    # Custom Data to send with each exception
    config_option :custom_data

    # Logger to use when if we find an exception :)
    config_option :logger

    # Should we actually report exceptions to Raygun? (Usually disabled in Development mode, for instance)
    config_option :enable_reporting

    # Failsafe logger (for exceptions that happen when we're attempting to report exceptions)
    config_option :failsafe_logger

    # Which controller method should we call to find out the affected user?
    config_option :affected_user_method

    # Mapping of methods for the affected user object - which methods should we call for user information
    config_option :affected_user_method_mapping

    # Which parameter keys should we filter out by default?
    config_option :filter_parameters

    # Exception classes to ignore by default
    IGNORE_DEFAULT = ['ActiveRecord::RecordNotFound',
                      'ActionController::RoutingError',
                      'ActionController::InvalidAuthenticityToken',
                      'CGI::Session::CookieStore::TamperedWithCookie',
                      'ActionController::UnknownAction',
                      'AbstractController::ActionNotFound',
                      'Mongoid::Errors::DocumentNotFound']

    DEFAULT_FILTER_PARAMETERS = [ :password, :card_number, :cvv ]

    attr_reader :defaults

    def initialize
      @config_values = {}

      # set default attribute values
      @defaults = OpenStruct.new({
        ignore:                           IGNORE_DEFAULT,
        custom_data:                      {},
        enable_reporting:                 true,
        affected_user_method:             :current_user,
        affected_user_method_mapping:     AffectedUser::MethodMapping.default_mapping,
        filter_parameters:                DEFAULT_FILTER_PARAMETERS
      })
    end

    def [](key)
      read_value(key)
    end

    def []=(key, value)
      set_value(key, value)
    end

    def silence_reporting
      !enable_reporting
    end

    def silence_reporting=(value)
      self.enable_reporting = !value
    end

    def affected_user_identifier_methods
      Raygun.deprecation_warning("Please note: You should now user config.affected_user_method_mapping.Identifier instead of config.affected_user_identifier_methods")
      read_value(:affected_user_method_mapping).Identifier
    end

    private

      def read_value(name)
        if @config_values.has_key?(name)
          @config_values[name]
        else
          @defaults.send(name)
        end
      end

      def set_value(name, value)
        @config_values[name] = value
      end

  end
end
