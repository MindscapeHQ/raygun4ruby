class Raygun::Railtie < Rails::Railtie
  initializer "raygun.insert_exception_middleware" do |app|
    app.middleware.insert_before ActionDispatch::ShowExceptions, Raygun::RackExceptionInterceptor
  end
end