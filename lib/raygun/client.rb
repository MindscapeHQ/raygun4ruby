module Raygun
  # client for the Raygun REST APIv1
  # as per http://raygun.io/raygun-providers/rest-json-api?v=1
  class Client

    ENV_IP_ADDRESS_KEYS = %w(action_dispatch.remote_ip raygun.remote_ip REMOTE_ADDR)
    NO_API_KEY_MESSAGE  = "[RAYGUN] Just a note, you've got no API Key configured, which means we can't report exceptions. Specify your Raygun API key using Raygun#setup (find yours at https://app.raygun.io)"

    include HTTParty

    base_uri "https://api.raygun.io/"

    def initialize
      @api_key = require_api_key
      @headers = {
        "X-ApiKey" => @api_key
      }

      enable_http_proxy if Raygun.configuration.proxy_settings[:address]
    end

    def require_api_key
      Raygun.configuration.api_key || print_api_key_warning
    end

    def track_exception(exception_instance, env = {})
      create_entry(build_payload_hash(exception_instance, env))
    end

    private

      def enable_http_proxy
        self.class.http_proxy(Raygun.configuration.proxy_settings[:address],
                              Raygun.configuration.proxy_settings[:port] || "80",
                              Raygun.configuration.proxy_settings[:username],
                              Raygun.configuration.proxy_settings[:password])
      end

      def client_details
        {
          name:      Raygun::CLIENT_NAME,
          version:   Raygun::VERSION,
          clientUrl: Raygun::CLIENT_URL
        }
      end

      def error_details(exception)
        {
          className:  exception.class.to_s,
          message:    exception.message.to_s.encode('UTF-16', :undef => :replace, :invalid => :replace).encode('UTF-8'),
          stackTrace: (exception.backtrace || []).map { |line| stack_trace_for(line) }
        }
      end

      def stack_trace_for(line)
        # see http://www.ruby-doc.org/core-2.0/Exception.html#method-i-backtrace
        file_name, line_number, method = line.split(":")
        {
          lineNumber: line_number,
          fileName:   file_name,
          methodName: method ? method.gsub(/^in `(.*?)'$/, "\\1") : "(none)"
        }
      end

      def hostname
        Socket.gethostname
      end

      def version
        Raygun.configuration.version
      end

      def user_information(env)
        env["raygun.affected_user"]
      end

      def affected_user_present?(env)
        !!env["raygun.affected_user"]
      end

      def rack_env
        ENV["RACK_ENV"]
      end

      def rails_env
        ENV["RAILS_ENV"]
      end

      def request_information(env)
        return {} if env.nil? || env.empty?
        {
          hostName:    env["SERVER_NAME"],
          url:         env["PATH_INFO"],
          httpMethod:  env["REQUEST_METHOD"],
          iPAddress:   "#{ip_address_from(env)}",
          queryString: Rack::Utils.parse_nested_query(env["QUERY_STRING"]),
          headers:     headers(env),
          form:        form_params(env),
          rawData:     raw_data(env)
        }
      end

      def headers(rack_env)
        rack_env.select { |k, v| k.to_s.start_with?("HTTP_") }.inject({}) do |hsh, (k, v)|
          hsh[normalize_raygun_header_key(k)] = v
          hsh
        end
      end

      def normalize_raygun_header_key(key)
        key.sub(/^HTTP_/, '')
           .sub(/_/, ' ')
           .split.map(&:capitalize).join(' ')
           .sub(/ /, '-')
      end

      def form_params(env)
        params = action_dispatch_params(env) || rack_params(env) || {}
        filter_params(params, env["action_dispatch.parameter_filter"])
      end

      def action_dispatch_params(env)
        env["action_dispatch.request.parameters"]
      end

      def rack_params(env)
        request = Rack::Request.new(env)
        request.params if env["rack.input"]
      end

      def raw_data(rack_env)
        request = Rack::Request.new(rack_env)
        unless request.form_data?
          form_params(rack_env)
        end
      end

      def filter_custom_data(env)
        params = env.delete(:custom_data) || {}
        filter_params(params, env["action_dispatch.parameter_filter"])
      end

      # see http://raygun.io/raygun-providers/rest-json-api?v=1
      def build_payload_hash(exception_instance, env = {})
        custom_data = filter_custom_data(env) || {}
        tags = env.delete(:tags) || []

        if rails_env
          tags << rails_env
        else
          tags << rack_env
        end

        grouping_key = env.delete(:grouping_key)

        error_details = {
            machineName:    hostname,
            version:        version,
            client:         client_details,
            error:          error_details(exception_instance),
            userCustomData: Raygun.configuration.custom_data.merge(custom_data),
            tags:           Raygun.configuration.tags.concat(tags).compact.uniq,
            request:        request_information(env)
        }

        error_details.merge!(groupingKey: grouping_key) if grouping_key

        error_details.merge!(user: user_information(env)) if affected_user_present?(env)

        if Raygun.configuration.filter_payload_with_whitelist
          error_details = filter_payload(error_details)
          error_details[:client] = client_details
        end

        {
          occurredOn: Time.now.utc.iso8601,
          details:    error_details
        }
      end

      def create_entry(payload_hash)
        self.class.post("/entries", verify_peer: true, verify: true, headers: @headers, body: JSON.generate(payload_hash))
      end

      def filter_params(params_hash, extra_filter_keys = nil)
        if Raygun.configuration.filter_payload_with_whitelist
          params_hash
        end
        if Raygun.configuration.filter_parameters.is_a?(Proc)
          filter_hash_with_proc(params_hash, Raygun.configuration.filter_parameters)
        else
          filter_keys = (Array(extra_filter_keys) + Raygun.configuration.filter_parameters).map(&:to_s)
          filter_params_with_array(params_hash, filter_keys)
        end
      end

      def filter_payload(payload_hash)
        if Raygun.configuration.filter_parameters.is_a?(Proc)
          filter_hash_with_proc(payload_hash, Raygun.configuration.filter_parameters)
        else
          filter_keys = Raygun.configuration.filter_parameters.map(&:to_s)
          filter_payload_with_array(payload_hash, filter_keys)
        end
      end

      def filter_hash_with_proc(hash, proc)
        proc.call(hash)
      end

      def filter_params_with_array(params_hash, filter_keys)
        # Recursive filtering of (nested) hashes
        (params_hash || {}).inject({}) do |result, (k, v)|
          result[k] = case v
          when Hash
            filter_params_with_array(v, filter_keys)
          else
            filter_keys.any? { |fk| /#{fk}/i === k.to_s } ? "[FILTERED]" : v
          end
          result
        end
      end

      def filter_payload_with_array(params_hash, filter_keys)
        # Whitelist filtering of (nested) hashes, only including filter_keys
        # that are defined in filter_parameters, recursively for both branch and leaf nodes
        (params_hash || {}).inject({}) do |result, (k, v)|
          if !filter_keys.any? { |fk| /#{fk}/i === k.to_s }
            result[k] = "[FILTERED]"
          elsif v.class == Hash
            result[k] = filter_payload_with_array(v, filter_keys)
          else
            result[k] = v
          end
          result
        end
      end


      def ip_address_from(env_hash)
        ENV_IP_ADDRESS_KEYS.each do |key_to_try|
          return env_hash[key_to_try] unless env_hash[key_to_try].nil? || env_hash[key_to_try] == ""
        end
        "(Not Available)"
      end

      def print_api_key_warning
        $stderr.puts(NO_API_KEY_MESSAGE)
      end

  end
end
