require "raygun/middleware/rails_insert_affected_user"

class Raygun::Railtie < Rails::Railtie
  def self.raygun_initialization(app)
    # Thanks Airbrake: See https://github.com/rails/rails/pull/8624
    middleware = if defined?(ActionDispatch::DebugExceptions)
                   if Rails::VERSION::MAJOR >= 5
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
    raygun_middleware = raygun_middleware.map(&:to_s) unless Rails::VERSION::MAJOR >= 5
    raygun_middleware.each do |m|
      app.config.middleware.insert_after(middleware, m)
    end
  end

  initializer "raygun.configure_rails_initialization" do |app|
    if Rails::VERSION::MAJOR >= 7
      ActiveSupport.on_load(:action_dispatch_request, run_once: true) do
        Raygun::Railtie.raygun_initialization(app)
      end
    else
      Raygun::Railtie.raygun_initialization(app)
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
