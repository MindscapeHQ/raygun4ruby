module Raygun
  # client for the Raygun REST APIv1
  # as per http://raygun.io/raygun-providers/rest-json-api?v=1
  class Client
    include HTTParty

    base_uri "https://api.raygun.io/"

    def initialize
      @api_key = require_api_key!

      @headers = {
        "X-ApiKey" => @api_key
      }
    end

    def require_api_key!
      Raygun.configuration.api_key || raise(ApiKeyRequired.new("Please specify your Raygun API key using Raygun#setup (find yours at https://app.raygun.io)"))
    end

    def track_exception(exception, env = {})
      self.class.post "/entries", headers: @headers,
                                  body: JSON.generate(Entry.new(exception, env).payload)
    end
  end
end
