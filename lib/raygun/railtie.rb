class Raygun::Railtie < Rails::Railtie

  after_initialize "raygun.configure_rails_initialization" do |app|
    if Raygun.configured?
      # Thanks Airbrake: See https://github.com/rails/rails/pull/8624
      middleware = if defined?(ActionDispatch::DebugExceptions)
        # Rails >= 3.2.0
        "ActionDispatch::DebugExceptions"
      else
        # Rails < 3.2.0
        "ActionDispatch::ShowExceptions"
      end

      app.config.middleware.insert_after middleware, "Raygun::Middleware::RackExceptionInterceptor"

      # Affected User tracking
      require "raygun/middleware/rails_insert_affected_user"
      app.config.middleware.insert_after Raygun::Middleware::RackExceptionInterceptor, "Raygun::Middleware::RailsInsertAffectedUser"
    end
  end

  config.to_prepare do
    Raygun.default_configuration.logger           = Rails.logger
    Raygun.default_configuration.enable_reporting = Rails.env.production?
  end

  rake_tasks do
    load "tasks/raygun.tasks"
  end

end
