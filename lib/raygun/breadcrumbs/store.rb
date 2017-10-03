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

      def self.record(
        message: nil,
        category: '',
        level: :info,
        timestamp: Time.now.utc.to_i,
        metadata: {},
        class_name: nil,
        method_name: nil,
        line_number: nil
      )
        raise ArgumentError.new('missing keyword: message') if message == nil
        crumb = Breadcrumb.new

        crumb.message = message
        crumb.category = category
        crumb.level = level
        crumb.metadata = metadata
        crumb.timestamp = timestamp
        crumb.type = 'manual'

        caller = caller_locations[1]
        crumb.class_name = class_name
        crumb.method_name = method_name || caller.label
        crumb.line_number = line_number || caller.lineno

        Thread.current[:breadcrumbs] << crumb if should_record?(crumb)
      end

      def self.any?
        stored != nil && stored.length > 0
      end

      private

      def self.should_record?(crumb)
        return false if stored.nil?

        levels = Raygun::Breadcrumbs::BREADCRUMB_LEVELS

        active_level = levels.index(Raygun.configuration.breadcrumb_level)
        crumb_level = levels.index(crumb.level) || -1

        discard = crumb_level < active_level

        if discard && Raygun.configuration.debug
          Raygun.log("[Raygun.breadcrumbs] discarding breadcrumb because #{crumb.level} is below active breadcrumb level (#{Raygun.configuration.breadcrumb_level})")
        end

        !discard
      end
    end
  end
end
