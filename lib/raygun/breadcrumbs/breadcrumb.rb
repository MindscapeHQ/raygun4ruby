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
          level: level,
          data: metadata,
          timestamp: timestamp,
        }
        payload[:location] = "#{class_name}:#{method_name}:#{line_number}" unless class_name == nil

        payload
      end
    end
  end
end
