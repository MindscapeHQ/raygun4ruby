module Raygun
  class RackExceptionInterceptor

    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue Exception => exception
      Raygun.track_exception(exception, env)
      raise exception
    end

  end
end