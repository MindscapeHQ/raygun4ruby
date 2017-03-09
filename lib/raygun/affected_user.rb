module Raygun
  class AffectedUser

    DEFAULT_MAPPING = {
      identifier: [ :id, :username ],
      email:      :email,
      full_name:  [ :full_name, :name ],
      first_name: :first_name,
      uuid:       :uuid
    }.freeze
    SUPPORTED_ATTRIBUTES = DEFAULT_MAPPING.keys.freeze
    NAME_TO_RAYGUN_NAME_MAPPING = {
      identifier: :Identifier,
      email: :Email,
      full_name: :FullName,
      first_name: :FirstName,
      uuid: :UUID
    }.freeze

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
        SUPPORTED_ATTRIBUTES.reduce({ IsAnonymous: false }) do |result, attribute|
          mapping = Raygun.configuration.affected_user_mapping
          method = mapping[attribute]

          value = if method.is_a? Proc
                    method.call(user_object)
                  else
                    attributes = Array(method)
                    attribute_to_use = attributes.select do |attr|
                      user_object.respond_to?(attr, true)
                    end.first

                    user_object.send(attribute_to_use) unless attribute_to_use == nil
                  end

          result[NAME_TO_RAYGUN_NAME_MAPPING[attribute]] = value unless value == nil
          result
        end
      end
    end
  end
end
