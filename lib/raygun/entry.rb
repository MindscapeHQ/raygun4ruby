module Raygun
  class Entry
    ENV_IP_ADDRESS_KEYS = %w(action_dispatch.remote_ip raygun.remote_ip REMOTE_ADDR)

    attr_reader :exception, :env, :request

    def initialize(exception, env)
      @exception = exception
      @env = env
      @request = Rack::Request.new(env)
    end
    def payload
      # see http://raygun.io/raygun-providers/rest-json-api?v=1
      custom_data = env.delete(:custom_data) || {}

      error_details = {
          machineName:    self.hostname,
          version:        self.version,
          client:         self.client_details,
          error:          self.error_details,
          userCustomData: Raygun.configuration.custom_data.merge(custom_data),
          request:        self.request_information
      }

      error_details.merge!(tags: error_tags) if error_tags_present?
      error_details.merge!(user: user_information) if affected_user_present?

      {
        occurredOn: Time.now.utc.iso8601,
        details:    error_details
      }
    end

    protected

      def error_details
        {
          className:  exception.class.to_s,
          message:    exception.message.encode('UTF-16', :undef => :replace, :invalid => :replace).encode('UTF-8'),
          stackTrace: (exception.backtrace || []).map { |line| stack_trace_for(line) }
        }
      end

      def hostname
        Socket.gethostname
      end

      def version
        Raygun.configuration.version
      end

      def user_information
        env["raygun.affected_user"]
      end

      def request_information
        return {} if env.nil? || env.empty?

        {
          hostName:    env["SERVER_NAME"],
          url:         env["PATH_INFO"],
          httpMethod:  env["REQUEST_METHOD"],
          iPAddress:   "#{self.ip_address}",
          queryString: Rack::Utils.parse_nested_query(env["QUERY_STRING"]),
          form:        self.form_data,
          headers:     self.headers,
          rawData:     self.raw_data
        }
      end

      def headers
        env.select { |k, v| k.to_s.start_with?("HTTP_") }.inject({}) do |hsh, (k, v)|
          hsh[normalize_raygun_header_key(k)] = v
          hsh
        end
      end

      def form_data
        filtered_params
      end

      def filtered_params
        filter_params(params)
      end

      def params
        env['action_dispatch.request.parameters'] || request.params || {}
      end

      def raw_data
        unless request.form_data?
          filter_params(env["action_dispatch.request.parameters"])
        end
      end

      def ip_address
        ENV_IP_ADDRESS_KEYS.each do |key_to_try|
          return env[key_to_try] unless env[key_to_try].nil? || env[key_to_try] == ""
        end
      end

      def client_details
        {
          name:      Raygun::CLIENT_NAME,
          version:   Raygun::VERSION,
          clientUrl: Raygun::CLIENT_URL
        }
      end

      def affected_user_present?
        !!env["raygun.affected_user"]
      end

      def error_tags
        [ENV["RACK_ENV"]]
      end

      def error_tags_present?
        !!ENV["RACK_ENV"]
      end

      def filter_keys
        (Array(env["action_dispatch.parameter_filter"]) + Raygun.configuration.filter_parameters).map(&:to_s)
      end

    private

      def stack_trace_for(line)
        # see http://www.ruby-doc.org/core-2.0/Exception.html#method-i-backtrace
        file_name, line_number, method = line.split(":")
        {
          lineNumber: line_number,
          fileName:   file_name,
          methodName: method ? method.gsub(/^in `(.*?)'$/, "\\1") : "(none)"
        }
      end

      def normalize_raygun_header_key(key)
        key.sub(/^HTTP_/, '')
           .sub(/_/, ' ')
           .split.map(&:capitalize).join(' ')
           .sub(/ /, '-')
      end

      def filter_params(params_hash)
        # Recursive filtering of (nested) hashes
        (params_hash || {}).inject({}) do |result, (k, v)|
          result[k] = case v
          when Hash
            filter_params(v)
          else
            filter_keys.include?(k) ? "[FILTERED]" : v
          end
          result
        end
      end
  end
end