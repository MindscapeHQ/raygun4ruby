begin
  require 'resque'
rescue LoadError
  raise "Can't find 'resque' gem. You'll need to require it before you require the Raygun Failure handler"
end

module Resque
  module Failure
    class Raygun < Base

      def save
        ::Raygun.track_exception(exception,
          custom_data: {
            resque: {
              worker: worker.to_s,
              queue:  queue.to_s,
              job:    payload['class'].to_s,
              args:   payload['args'].inspect
            }
          }
        )
      end

    end
  end
end