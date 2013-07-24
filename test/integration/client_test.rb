require_relative "../test_helper.rb"

class ClientTest < Raygun::IntegrationTest

  class InnocentTestException < StandardError
    def message
      "I am nothing but a test exception"
    end
  end

  def test_sending_a_sample_exception
    begin
      raise InnocentTestException.new
    rescue InnocentTestException => e
      response = Raygun.track_exception(e)
      assert_equal 202, response.code, "Raygun Request Failed: #{response.inspect}"
    end
  end

end