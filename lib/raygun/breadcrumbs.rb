module Raygun
  module Breadcrumbs
    BREADCRUMB_LEVELS = [
      :debug,
      :info,
      :warning,
      :error,
      :fatal
    ]

    def record_breadcrumb(&block)
      crumb = Breadcrumb.new
      crumb.class_name = self.class.name

      Breadcrumbs::Store.record(crumb, &block)
    end
  end
end
