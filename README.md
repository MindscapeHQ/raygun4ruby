# Raygun 4 Ruby [![Build Status](https://travis-ci.org/MindscapeHQ/raygun4ruby.png?branch=master)](https://travis-ci.org/MindscapeHQ/raygun4ruby) [![Gem Version](https://badge.fury.io/rb/raygun4ruby.svg)](https://badge.fury.io/rb/raygun4ruby)

This is the Ruby adapter for the Raygun error reporter, http://raygun.io.


## Installation

Add this line to your application's Gemfile:

    gem 'raygun4ruby'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install raygun4ruby

## Usage

### Rails 3/4

Run:

    rails g raygun:install YOUR_API_KEY_HERE

You can find your API key on your [Raygun Dashboard](https://app.raygun.io/dashboard/)

You can then test your Raygun integration by running:

    rake raygun:test

You should see an "ItWorksException" appear in your Raygun dashboard. You're ready to zap those errors!

NB: Raygun4Ruby currently requires Ruby >= 1.9

Note that the generator will create a file in `config/initializers` called "raygun.rb". If you need to do any further configuration or customization of Raygun, that's the place to do it!

By default the Rails integration is set to only report Exceptions in Production. To change this behaviour, set `config.enable_reporting` to something else in `config/initializers/raygun.rb`.

### Rails 2

Raygun4Ruby doesn't currently support Rails 2. If you'd like Rails 2 support, [drop us a line](http://raygun.io/forums).

### Sinatra

To enable exception tracking in Sinatra, just add configure Raygun and use the Rack middleware in your app:

```ruby
require 'raygun4ruby'
Raygun.setup do |config|
  config.api_key = "YOUR_API_KEY_HERE"
end
use Raygun::Middleware::RackExceptionInterceptor
```

### Standalone / Manual Exception Tracking

```ruby

require 'rubygems'
require 'raygun4ruby'

Raygun.setup do |config|
  config.api_key = "YOUR_RAYGUN_API_KEY"
  config.filter_parameters = [ :password, :card_number, :cvv ] # don't forget to filter out sensitive parameters
  config.enable_reporting = Rails.env.production? # true to send errors, false to not log
end

begin
  # your lovely code here
rescue Exception => e
  Raygun.track_exception(e)
end

# You may also pass a user object as the third argument to allow affected user tracking, like so
begin
  # your lovely code here
rescue Exception => e
  # The second argument is the request environment variables
  Raygun.track_exception(e, {}, user)
end
```

You can also pass a Hash as the second parameter to `track_exception`. It should look like a [Rack Env Hash](http://rack.rubyforge.org/doc/SPEC.html)

### Customizing The Parameter Filtering

If you'd like to customize how parameters are filtered, you can pass a `Proc` to `filter_parameters`. Raygun4Ruby will yield the params hash to the block, and the return value will be sent along with your error.

```ruby
Raygun.setup do |config|
  config.api_key = "YOUR_RAYGUN_API_KEY"
  config.filter_parameters do |params|
    params.slice("only", "a", "few", "keys") # note that Hash#slice is in ActiveSupport
  end
end
```

### Filtering the payload by whitelist

As an alternative to the above, you can also opt-in to the keys/values to be sent to Raygun by providing a specific whitelist of the keys you want to transmit.

This disables the blacklist filtering above (`filter_parameters`), and is applied to the entire payload (error, request, environment and custom data included), not just the request parameters.

In order to opt-in to this feature, set `filter_payload_with_whitelist` to `true`, and specify a shape of what keys you want (the default is below which is to allow everything through, this also means that the query parameters filtered out by default like password, creditcard etc will not be unless changed):

```ruby
Raygun.setup do |config|
  config.api_key = "YOUR_RAYGUN_API_KEY"
  config.filter_payload_with_whitelist = true

  config.whitelist_payload_shape = {
      machineName: true,
      version: true,
      error: true,
      userCustomData: true,
      tags: true,
      request: {
        hostName: true,
        url: true,
        httpMethod: true,
        iPAddress: true,
        queryString: true,
        headers: true,
        form: {}, # Set to empty hash so that it doesn't just filter out the whole thing, but instead filters out each individual param
        rawData: true
      }
    }
end
```

Alternatively, provide a Proc to filter the payload using your own logic:

```ruby
Raygun.setup do |config|
  config.api_key = "YOUR_RAYGUN_API_KEY"
  config.filter_payload_with_whitelist = true

  config.whitelist_payload_keys do |payload|
    # Return the payload mutated into your desired form
    payload
  end
end
```

### Custom User Data
Custom data can be added to `track_exception` by passing a custom_data key in the second parameter hash.

```ruby

begin
  # more lovely code
rescue Exception => e
  Raygun.track_exception(e, custom_data: {my: 'custom data', goes: 'here'})
end

```

Custom data can also be specified globally either by setting `config.custom_data` to a hash

```ruby
Raygun.setup do |config|
  config.api_key = "YOUR_RAYGUN_API_KEY"
  config.custom_data = {custom_data: 'goes here'}
end
```

or to a proc, which gets passed the exception and environment hash

```ruby
Raygun.setup do |config|
  config.api_key = "YOUR_RAYGUN_API_KEY"
  config.custom_data do |e, env|
    {message: e.message, server: env["SERVER_NAME"]}
  end
end
```

### Ignoring Some Errors

You can ignore certain types of Exception using the `ignore` option in the setup block, like so:

```ruby
Raygun.setup do |config|
  config.api_key = "MY_SWEET_API_KEY"
  config.ignore  << ['MyApp::AnExceptionIDontCareAbout']
end
```

The following exceptions are ignored by default: 

```
ActiveRecord::RecordNotFound
ActionController::RoutingError
ActionController::InvalidAuthenticityToken
ActionDispatch::ParamsParser::ParseError
CGI::Session::CookieStore::TamperedWithCookie
ActionController::UnknownAction
AbstractController::ActionNotFound
Mongoid::Errors::DocumentNotFound
```

 [You can see this here](https://github.com/MindscapeHQ/raygun4ruby/blob/master/lib/raygun/configuration.rb#L51) and unignore them if needed by doing the following:

```ruby
Raygun.setup do |config|
  config.api_key = "MY_SWEET_API_KEY"
  config.ignore.delete('ActionController::InvalidAuthenticityToken')
end
```

### Using a Proxy

You can pass proxy settings using the `proxy_settings` config option.

```ruby
Raygun.setup do |config|
  config.api_key = "MY_SWEET_API_KEY"
  config.proxy_settings = { host: "localhost", port: 8888 }
end
```

### Affected User Tracking

Raygun can now track how many users have been affected by an error.

By default, Raygun looks for a method called `current_user` on your controller, and it will populate the user's information based on a default method name mapping.

(e.g Raygun will call `email` to populate the user's email, and `first_name` for the user's first name)

You can inspect and customize this mapping using `config.affected_user_mapping`, like so:

```ruby
Raygun.setup do |config|
  config.api_key = "MY_SWEET_API_KEY"
  config.affected_user_method = :my_current_user # `current_user` by default
  # To augment the defaults with your unique methods you can do the following
  config.affected_user_mapping = Raygun::AffectedUser::DEFAULT_MAPPING.merge({
    identifier: :some_custom_unique_identifier,
    # If you set the key to a proc it will be passed the user object and you can construct the value your self
    full_name: ->(user) { "#{user.first_name} #{user.last_name}" }
  })
end
```

To see the defaults check out [affected_user.rb](https://github.com/MindscapeHQ/raygun4ruby/tree/master/lib/raygun/affected_user.rb)

If you're using Rails, most authentication systems will have this method set and you should be good to go.

The count of unique affected users will appear on the error group in the Raygun dashboard. If your user has an `Email` attribute, and that email has a Gravatar associated with that address, you will also see your user's avatar.

If you wish to keep it anonymous, you could set this identifier to something like `SecureRandom.uuid` and store that in a cookie, like so:

```ruby
class ApplicationController < ActionController::Base

  def raygun_user
    cookies.permanent[:raygun_user_identifier] ||= SecureRandom.uuid
  end

end
```

(Remember to set `affected_user_method` to `:raygun_user` in your config block...)

### Version tracking

Raygun can attach the version of your application to its error reports. In your Raygun.setup block, set `version` to the current version of your app.

```ruby
Raygun.setup do |config|
  config.version = "1.0.0.4" # you could also pull this from ENV or however you want to set it.
end
```

### Tags

Raygun allows you to tag error reports with any number of tags. In your Raygun.setup block, set `tags` to an array of strings to have those
set on any error reports sent by the gem.

```ruby
Raygun.setup do |config|
  config.tags = ['heroku']
end
```

### Resque Error Tracking

Raygun4Ruby also includes a Resque failure backend. You should include it inside your Resque initializer (usually something like `config/initializers/load_resque.rb`)

```ruby
require 'resque/failure/multiple'
require 'resque/failure/raygun'
require 'resque/failure/redis'

Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Raygun]
Resque::Failure.backend = Resque::Failure::Multiple
```

### Sidekiq Error Tracking

Raygun4Ruby can track errors from Sidekiq (2.x or 3+). All you need to do is add the line:

```ruby
  require 'raygun/sidekiq'
```

Either in your Raygun initializer or wherever else takes your fancy :)

### Other Configuration options

For a complete list of configuration options see the [configuration.rb](https://github.com/MindscapeHQ/raygun4ruby/blob/master/lib/raygun/configuration.rb) file

## Found a bug?

Oops! Just let us know by opening an Issue on Github.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Building

1. Build the gem (`gem build raygun4ruby.gemspec`) - don't bother trying to build it on Windows,
the resulting Gem won't work.
2. Install the gem (`gem install raygun4ruby-VERSION.gem`)
