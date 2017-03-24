module Raygun
  module Breadcrumbs
    class Breadcrumb
      ATTRIBUTES = [
        :message, :category, :metadata, :class_name,
        :method_name, :line_number, :timestamp
      ]
      attr_accessor(*ATTRIBUTES)
    end
  end
end
