module Raygun
  module Middleware
    class RackExceptionInterceptor

      def initialize(app)
        @app = app
      end

      def call(env)
        response = @app.call(env)
      rescue Exception => exception
        Raygun.track_exception(exception, env) if Raygun.configured?
        raise exception
      end

    end
  end
end
