module Raygun
  class InstallGenerator < Rails::Generators::Base

    argument :api_key

    desc "This generator creates a configuration file for the Raygun ruby adapter inside config/initializers"
    def create_configuration_file
      filter_parameters = if defined?(Rails)
                            "config.filter_parameters = Rails.application.config.filter_parameters"
                          else
                            "config.filter_parameters = [ :password, :card_number, :cvv ] # don't forget to filter out sensitive parameters"
                          end
      initializer "raygun.rb" do
        <<-EOS
Raygun.setup do |config|
  config.api_key = "#{api_key}"
  #{filter_parameters}

  # The default is Rails.env.production?
  # config.enable_reporting = !Rails.env.development? && !Rails.env.test?
end
EOS
      end
    end
  end
end
