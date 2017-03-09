module Raygun
  module Middleware
    # Adapted from the Rollbar approach https://github.com/rollbar/rollbar-gem/blob/master/lib/rollbar/middleware/rails/rollbar_request_store.rb
    class RailsInsertAffectedUser

      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue Exception => exception
        controller = env["action_controller.instance"]
        affected_user_method = Raygun.configuration.affected_user_method

        if controller && controller.respond_to?(affected_user_method, true)
          user = controller.send(affected_user_method)

          env["raygun.affected_user"] = Raygun::AffectedUser.information_hash(user)
        end

        raise exception
      end
    end
  end
end
