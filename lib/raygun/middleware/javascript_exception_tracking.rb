module Raygun::Middleware
  class JavascriptExceptionTracking
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)

      # It's a html file, inject our JS
      if headers['Content-Type'].include?('text/html')
        response = inject_javascript_to_response(response)
      end

      [status, headers, response]
    end

    def inject_javascript_to_response(response)
      response[0].gsub!('</head>', "#{js_tracker.head_html}</head>")
      response[0].gsub!('</body>', "#{js_tracker.body_html}</body>")

      response
    end

    private
    def js_tracker
      @js_tracker = Raygun::JavaScriptTracker.new
    end
  end
end
