module Raygun

  class ItWorksException < StandardError; end

  module Testable

    def track_test_exception
      Raygun.configuration.silence_reporting = false
      raise ItWorksException.new("Woohoo! Your Raygun<->Ruby connection is set up correctly")
    rescue ItWorksException => e
      if Raygun.track_exception(e).success?
        puts "Success! Now go check your Raygun.io Dashboard"
      else
        puts "Oh-oh, something went wrong - double check your API key"
      end
    end

  end
end