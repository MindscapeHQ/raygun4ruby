class Raygun::Railtie < Rails::Railtie

  initializer "raygun.configure_rails_initialization" do |app|

    # Thanks Airbrake: See https://github.com/rails/rails/pull/8624
    middleware = if defined?(ActionDispatch::DebugExceptions)
      # Rails >= 3.2.0
      "ActionDispatch::DebugExceptions"
    else
      # Rails < 3.2.0
      "ActionDispatch::ShowExceptions"
    end

    app.config.middleware.insert_after middleware, "Raygun::RackExceptionInterceptor"
  end

  config.to_prepare do
    Raygun.configuration.logger          ||= Rails.logger
    Raygun.configuration.silence_reporting = !Rails.env.production? if Raygun.configuration.silence_reporting.nil?
  end

  rake_tasks do
    load "tasks/raygun.tasks"
  end

end