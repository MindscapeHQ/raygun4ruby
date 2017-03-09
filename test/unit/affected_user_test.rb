require_relative "../test_helper.rb"
require 'ostruct'
require 'raygun/middleware/rails_insert_affected_user'

class AffectedUserTest < Raygun::UnitTest

  class TestException < StandardError; end

  class MockController

    def user_with_email
      OpenStruct.new(id: 123, email: "testemail@something.com")
    end

    def user_with_login
      OpenStruct.new(login: "topsecret")
    end

    def user_with_full_details
      OpenStruct.new(id: 123, email: "testemail@something.com", first_name: "Taylor", last_name: "Lodge")
    end

    def user_as_string
      "some-string-identifier"
    end

    def no_logged_in_user
    end

    private

      def private_current_user
        user_with_email
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
      user_hash = { :Identifier => 123, :Email => "testemail@something.com", :IsAnonymous => false }
      assert_equal user_hash, @app.env["raygun.affected_user"]
    end
  end

  def test_changing_method_mapping
    Raygun.configuration.affected_user_method = :user_with_login
    Raygun.configuration.affected_user_mapping = {
      identifier: :login
    }

    assert @controller.respond_to?(Raygun.configuration.affected_user_method)

    begin
      @middleware.call("action_controller.instance" => @controller)
    rescue TestException
      user_hash = { :Identifier => "topsecret", :IsAnonymous => false }
      assert_equal user_hash, @app.env["raygun.affected_user"]
    end
  end

  def test_inserting_user_as_plain_string
    Raygun.configuration.affected_user_method = :user_as_string
    assert @controller.respond_to?(Raygun.configuration.affected_user_method)

    begin
      @middleware.call("action_controller.instance" => @controller)
    rescue TestException
      user_hash = { :Identifier => "some-string-identifier", :IsAnonymous => true }
      assert_equal user_hash, @app.env["raygun.affected_user"]
    end
  end

  def test_with_a_nil_user
    Raygun.configuration.affected_user_method = :no_logged_in_user
    assert @controller.respond_to?(Raygun.configuration.affected_user_method)

    begin
      @middleware.call("action_controller.instance" => @controller)
    rescue TestException
      user_hash = { :IsAnonymous => true }
      assert_equal user_hash, @app.env["raygun.affected_user"]
    end
  end

  def test_with_private_method
    Raygun.configuration.affected_user_method = :private_current_user
    assert @controller.respond_to?(Raygun.configuration.affected_user_method, true)

    begin
      @middleware.call("action_controller.instance" => @controller)
    rescue TestException
      user_hash = {:IsAnonymous=>false, :Identifier=>123, :Email=>"testemail@something.com"}
      assert_equal user_hash, @app.env["raygun.affected_user"]
    end
  end

  def test_with_proc_for_mapping
    Raygun.configuration.affected_user_method = :user_with_full_details
    Raygun.configuration.affected_user_mapping = Raygun::AffectedUser::DEFAULT_MAPPING.merge({
      full_name: ->(user) { "#{user.first_name} #{user.last_name}" }
    })

    assert @controller.respond_to?(Raygun.configuration.affected_user_method, true)

    begin
      @middleware.call("action_controller.instance" => @controller)
    rescue TestException
      user_hash = {:IsAnonymous=>false, :Identifier=>123, :Email=>"testemail@something.com", :FullName => "Taylor Lodge", :FirstName => "Taylor"}
      assert_equal user_hash, @app.env["raygun.affected_user"]
    end
  end
end
