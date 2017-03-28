module Raygun
  module Breadcrumbs
    BREADCRUMB_LEVELS = [
      :debug,
      :info,
      :warning,
      :error,
      :fatal
    ]

    def record_breadcrumb(
        message: nil,
        category: '',
        level: :info,
        timestamp: Time.now.utc,
        metadata: {},
        class_name: nil,
        method_name: nil,
        line_number: nil
    )
      class_name = class_name || self.class.name
      Breadcrumbs::Store.record(
        message: message,
        category: category,
        level: level,
        timestamp: timestamp,
        metadata: metadata,
        class_name: class_name,
        method_name: method_name,
        line_number: line_number,
      )
    end
  end
end
