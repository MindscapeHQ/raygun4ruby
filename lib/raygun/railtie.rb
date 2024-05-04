require "raygun/middleware/rails_insert_affected_user"

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

    raygun_middleware = [
      Raygun::Middleware::RailsInsertAffectedUser,
      Raygun::Middleware::RackExceptionInterceptor,
      Raygun::Middleware::BreadcrumbsStoreInitializer,
      Raygun::Middleware::JavascriptExceptionTracking
    ]
    raygun_middleware = raygun_middleware.map(&:to_s) unless Rails::VERSION::STRING >= "5"
    raygun_middleware.each do |m|
      app.config.middleware.insert_after(middleware, m)
    end
  end

  config.to_prepare do
    Raygun.default_configuration.logger           = Rails.logger
    Raygun.default_configuration.enable_reporting = Rails.env.production?

    Raygun::Railtie.setup_error_subscriber
  end

  rake_tasks do
    load "tasks/raygun.tasks"
  end

  def self.setup_error_subscriber
    if ::Rails.version.to_f >= 7.0 && Raygun.configuration.register_rails_error_handler
      Rails.error.subscribe(Raygun::ErrorSubscriber.new)
    end
  end
end
