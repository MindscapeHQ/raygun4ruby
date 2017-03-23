module Raygun
  class Breadcrumb
    attr_accessor :message, :category, :metadata, :class_name, :method_name, :line_number
  end
end
