require_relative 'breadcrumb'

module Raygun
  module Breadcrumbs
    class Store
      def self.initialize
        Thread.current[:breadcrumbs] ||= []
      end

      def self.clear
        Thread.current[:breadcrumbs] = nil
      end

      def self.stored
        Thread.current[:breadcrumbs]
      end

      def self.record(crumb = nil, &block)
        crumb = Breadcrumb.new if crumb == nil

        block.call(crumb)

        caller = caller_locations[1]
        crumb.method_name = caller.label if crumb.method_name == nil
        crumb.line_number = caller.lineno
        crumb.timestamp = Time.now.utc if crumb.timestamp == nil
        crumb.level = :info if crumb.level == nil

        Thread.current[:breadcrumbs] << crumb if should_record?(crumb)
      end

      def self.any?
        stored != nil && stored.length > 0
      end

      private

      def self.should_record?(crumb)
        levels = Raygun::Breadcrumbs::BREADCRUMB_LEVELS

        active_level = levels.index(Raygun.configuration.breadcrumb_level)
        crumb_level = levels.index(crumb.level) || -1

        crumb_level >= active_level
      end
    end
  end
end
