module Raygun
  class Error < StandardError
    attr_reader :raygun_custom_data

    def initialize(message, raygun_custom_data = {})
      super(message)
      @raygun_custom_data = raygun_custom_data
    end
  end
end
