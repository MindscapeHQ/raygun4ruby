module Raygun
  module Breadcrumbs
    class Breadcrumb
      ATTRIBUTES = [
        :message, :category, :metadata, :class_name,
        :method_name, :line_number, :timestamp, :level
      ]
      attr_accessor(*ATTRIBUTES)

      def build_payload
        payload = {
          message: message,
          category: category,
          level: Breadcrumbs::BREADCRUMB_LEVELS.index(level),
          timestamp: timestamp,
        }

        payload[:CustomData] = metadata unless metadata == nil
        payload[:location] = "#{class_name}:#{method_name}" unless class_name == nil
        payload[:location] += ":#{line_number}" if payload.has_key?(:location) && line_number != nil

        payload
      end
    end
  end
end
