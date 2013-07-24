module Raygun
  # client for the Raygun REST APIv1
  # as per http://raygun.io/raygun-providers/rest-json-api?v=1
  class Client
    include HTTParty

    base_uri "https://api.raygun.io/"

    def initialize
      @headers = {
        "X-ApiKey" => Raygun.configuration.api_key
      }
    end

    def track_exception(exception_instance, env = {})
      create_entry(build_payload_hash(exception_instance, env))
    end

    private

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
          message:    exception.message,
          stackTrace: exception.backtrace.map { |line| stack_trace_for(line) }
        }
      end

      def stack_trace_for(line)
        # see http://www.ruby-doc.org/core-2.0/Exception.html#method-i-backtrace
        file_name, line_number, method = line.split(":")
        {
          lineNumber: line_number,
          fileName:   file_name,
          methodName: method.gsub(/^in `(.*?)'$/, "\\1")
        }
      end

      def hostname
        Socket.gethostname
      end

      def version
        Raygun.configuration.version
      end

      # see http://raygun.io/raygun-providers/rest-json-api?v=1
      def build_payload_hash(exception_instance, env)
        {
          occurredOn: Time.now.utc.iso8601,
          details: {
            machineName:    hostname,
            version:        version,
            client:         client_details,
            error:          error_details(exception_instance),
            userCustomData: Raygun.configuration.custom_data,
            request:        request_information(env)
          }
        }
      end

      def request_information(env)
        return {} if env.blank?
      end

      def create_entry(payload_hash)
        self.class.post("/entries", headers: @headers, body: JSON.generate(payload_hash))
      end

  end
end