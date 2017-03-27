module Raygun
  module Middleware
    class BreadcrumbsStoreInitializer
      def initialize(app)
        @app = app
      end

      def call(env)
        Breadcrumbs::Store.initialize

        begin
          @app.call(env)
        ensure
          Breadcrumbs::Store.clear
        end
      end
    end
  end
end
