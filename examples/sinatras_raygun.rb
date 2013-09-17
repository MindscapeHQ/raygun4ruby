# NB: You'll need to install the 'sinatra' gem for this to work :)
# $ gem install sinatra
# $ ruby sinatras_raygun.rb

require 'sinatra'
require_relative '../lib/raygun4ruby'

Raygun.setup do |config|
  config.api_key = YOUR_RAYGUN_API_KEY_HERE
end

use Raygun::RackExceptionInterceptor

set :raise_errors, true

get '/' do
  raise "This is an exception that will be sent to Raygun!"
end