module Raygun

  class ItWorksException < StandardError; end

  module Testable

    def track_test_exception
      Raygun.configuration.silence_reporting = false
      raise ItWorksException.new("Woohoo! Your Raygun<->Ruby connection is set up correctly")
    rescue ItWorksException => e
      response = Raygun.track_exception(e)

      if response.success?
        puts "Success! Now go check your Raygun.io Dashboard"
      else
        puts "Oh-oh, something went wrong - double check your API key"
        puts "API Key - " << Raygun.configuration.api_key << ")"
        puts "API Response - " << response
      end
    end

  end
end