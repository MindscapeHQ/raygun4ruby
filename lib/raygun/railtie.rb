class Raygun::Railtie < Rails::Railtie
  initializer "raygun.configure_rails_initialization" do |app|

    # Thanks Airbrake: See https://github.com/rails/rails/pull/8624
    middleware = if defined?(ActionDispatch::DebugExceptions)
      if Rails::VERSION::STRING >= "5"
        ActionDispatch::DebugExceptions
      else
        # Rails >= 3.2.0
        "ActionDispatch::DebugExceptions"
      end
    else
      # Rails < 3.2.0
      "ActionDispatch::ShowExceptions"
    end

    raygun_middleware = Raygun::Middleware::RackExceptionInterceptor
    raygun_middleware = raygun_middleware.to_s unless Rails::VERSION::STRING >= "5"
    app.config.middleware.insert_after middleware, raygun_middleware

    # Affected User tracking
    require "raygun/middleware/rails_insert_affected_user"
    affected_user_middleware = Raygun::Middleware::RailsInsertAffectedUser
    affected_user_middleware = affected_user_middleware.to_s unless Rails::VERSION::STRING >= "5"
    app.config.middleware.insert_after Raygun::Middleware::RackExceptionInterceptor, affected_user_middleware
  end

  config.to_prepare do
    Raygun.default_configuration.logger           = Rails.logger
    Raygun.default_configuration.enable_reporting = Rails.env.production?
  end

  rake_tasks do
    load "tasks/raygun.tasks"
  end
end
