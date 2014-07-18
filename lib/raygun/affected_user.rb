module Raygun
  class AffectedUser

    DEFAULT_METHOD_MAPPING = {
      Identifier:   [ :id, :username ],
      Email:        :email,
      FullName:     [ :full_name, :name ],
      FirstName:    :first_name,
      UUID:         :uuid
    }

    SUPPORTED_ATTRIBUTES = DEFAULT_METHOD_MAPPING.keys

    class MethodMapping < Struct.new(*SUPPORTED_ATTRIBUTES)
      def self.default_mapping
        new(*DEFAULT_METHOD_MAPPING.values)
      end
    end

    class << self

      def information_hash(user_object)
        if user_object.nil? || user_object.is_a?(String)
          handle_anonymous_user(user_object)
        else
          handle_known_user(user_object)
        end
      end

      private

        def handle_anonymous_user(user_object)
          result = { IsAnonymous: true }
          result[:Identifier] = user_object unless user_object.nil?
          result
        end

        def handle_known_user(user_object)
          SUPPORTED_ATTRIBUTES.inject({ IsAnonymous: false }) do |result, attribute|

            methods_to_try    = Array(Raygun.configuration.affected_user_method_mapping.send(attribute))

            value = if (m = methods_to_try.detect { |m| user_object.respond_to?(m) })
              user_object.send(m)
            end

            result[attribute] = value unless value.nil?
            result
          end
        end

    end

  end
end
