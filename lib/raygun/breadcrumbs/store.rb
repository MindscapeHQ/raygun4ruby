require_relative 'breadcrumb'

module Raygun
  module Breadcrumbs
    class Store
      def self.initialize_store
        Thread.current[:breadcrumbs] ||= []
      end

      def self.clear_store
        Thread.current[:breadcrumbs] = nil
      end

      def self.stored
        Thread.current[:breadcrumbs]
      end

      def self.record(crumb = nil, &block)
        crumb = Breadcrumb.new if crumb == nil

        block.call(crumb)
        crumb.method_name = caller_locations[1].label if crumb.method_name == nil
        crumb.timestamp = Time.now.utc if crumb.timestamp == nil

        Thread.current[:breadcrumbs] << crumb
      end

      def self.any?
        stored != nil && stored.length > 0
      end
    end
  end
end
