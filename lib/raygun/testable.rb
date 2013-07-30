module Raygun
  module Testable

    class ItWorksException < StandardError; end

    def track_test_exception
      Raygun.track_exception(ItWorksException.new("Woohoo!"))
    end

  end
end