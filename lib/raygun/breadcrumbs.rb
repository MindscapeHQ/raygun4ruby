module Raygun
  class Breadcrumbs
    def self.initialize_store
      Thread.current[:breadcrumbs] ||= []
    end

    def self.clear_store
      Thread.current[:breadcrumbs] = nil
    end

    def self.stored
      Thread.current[:breadcrumbs]
    end
  end
end
