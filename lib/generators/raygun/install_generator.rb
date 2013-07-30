module Raygun
  class InstallGenerator < Rails::Generators::Base

    argument :api_key

    desc "This generator creates a configuration file for the Raygun ruby adapter inside config/initializers"
    def create_configuration_file
      initializer "raygun.rb" do
        <<-EOS
Raygun.setup do |config|
  config.api_key = "#{api_key}"
end
EOS
      end
    end
  end
end