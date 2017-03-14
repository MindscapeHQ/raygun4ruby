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

    def self.proc_config_option(name)
      define_method(name) do |&block|
        set_value(name, block) unless block == nil
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
    proc_config_option :custom_data

    # Tags to send with each exception
    config_option :tags

    # Logger to use when we find an exception :)
    config_option :logger

    # Should we actually report exceptions to Raygun? (Usually disabled in Development mode, for instance)
    config_option :enable_reporting

    # Failsafe logger (for exceptions that happen when we're attempting to report exceptions)
    config_option :failsafe_logger

    # Which controller method should we call to find out the affected user?
    config_option :affected_user_method

    # Mapping of methods for the affected user object - which methods should we call for user information
    config_option :affected_user_mapping

    # Which parameter keys should we filter out by default?
    proc_config_option :filter_parameters

    # Should we switch to a white listing mode for keys instead of the default blacklist?
    config_option :filter_payload_with_whitelist

    # If :filter_payload_with_whitelist is true, which keys should we whitelist?
    proc_config_option :whitelist_payload_shape

    # Hash of proxy settings - :address, :port (defaults to 80), :username and :password (both default to nil)
    config_option :proxy_settings

    # Set this to true to have raygun4ruby log the reason why it skips reporting an exception
    config_option :debug

    # Override this if you wish to connect to a different Raygun API than the standard one
    config_option :api_url

    # Exception classes to ignore by default
    IGNORE_DEFAULT = ['ActiveRecord::RecordNotFound',
                      'ActionController::RoutingError',
                      'ActionController::InvalidAuthenticityToken',
                      'ActionDispatch::ParamsParser::ParseError',
                      'CGI::Session::CookieStore::TamperedWithCookie',
                      'ActionController::UnknownAction',
                      'AbstractController::ActionNotFound',
                      'Mongoid::Errors::DocumentNotFound']

    DEFAULT_FILTER_PARAMETERS = [ :password, :card_number, :cvv ]

    DEFAULT_WHITELIST_PAYLOAD_SHAPE_REQUEST = {
      hostName: true,
      url: true,
      httpMethod: true,
      iPAddress: true,
      queryString: true,
      headers: true,
      form: {}, # Set to empty hash so that it doesn't just filter out the whole thing, but instead filters out each individual param
      rawData: true
    }.freeze
    DEFAULT_WHITELIST_PAYLOAD_SHAPE = {
      machineName: true,
      version: true,
      error: true,
      userCustomData: true,
      tags: true,
      request: DEFAULT_WHITELIST_PAYLOAD_SHAPE_REQUEST
    }.freeze

    attr_reader :defaults

    def initialize
      @config_values = {}

      # set default attribute values
      @defaults = OpenStruct.new({
        ignore:                           IGNORE_DEFAULT,
        custom_data:                      {},
        tags:                             [],
        enable_reporting:                 true,
        affected_user_method:             :current_user,
        affected_user_mapping:            AffectedUser::DEFAULT_MAPPING,
        filter_parameters:                DEFAULT_FILTER_PARAMETERS,
        filter_payload_with_whitelist:    false,
        whitelist_payload_shape:          DEFAULT_WHITELIST_PAYLOAD_SHAPE,
        proxy_settings:                   {},
        debug:                            false,
        api_url:                          'https://api.raygun.io/'
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
