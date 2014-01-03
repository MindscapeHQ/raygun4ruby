require_relative "../test_helper.rb"
require 'ostruct'
require 'raygun/middleware/rails_insert_affected_user'

class ClientTest < Raygun::UnitTest

  class TestException < StandardError; end

  class MockController

    def user_with_email
      OpenStruct.new(email: "testemail@something.com")
    end

    def user_with_login
      OpenStruct.new(login: "topsecret")
    end

    def user_as_string
      "some-string-identifier"
    end
  end

  class MockApp
    attr_accessor :env

    def call(env)
      @env = env
      raise TestException.new
    end
  end

  def setup
    super
    @client = Raygun::Client.new
    fake_successful_entry

    @app        = MockApp.new
    @controller = MockController.new
    @middleware = Raygun::Middleware::RailsInsertAffectedUser.new(@app)
  end

  def test_inserting_user_object_with_email
    Raygun.configuration.affected_user_method = :user_with_email
    assert @controller.respond_to?(Raygun.configuration.affected_user_method)

    begin
      @middleware.call("action_controller.instance" => @controller)
    rescue TestException 
      user_hash = { :identifier => "testemail@something.com" }
      assert_equal user_hash, @app.env["raygun.affected_user"]
    end
  end

  def test_inserting_user_object_with_login
    Raygun.configuration.affected_user_method = :user_with_login
    Raygun.configuration.affected_user_identifier_methods << :login
    
    assert @controller.respond_to?(Raygun.configuration.affected_user_method)

    begin
      @middleware.call("action_controller.instance" => @controller)
    rescue TestException 
      user_hash = { :identifier => "topsecret" }
      assert_equal user_hash, @app.env["raygun.affected_user"]
    end
  end

  def test_inserting_user_as_plain_string
    Raygun.configuration.affected_user_method = :user_as_string
    assert @controller.respond_to?(Raygun.configuration.affected_user_method)

    begin
      @middleware.call("action_controller.instance" => @controller)
    rescue TestException 
      user_hash = { :identifier => "some-string-identifier" }
      assert_equal user_hash, @app.env["raygun.affected_user"]
    end
  end

end
