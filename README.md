# Raygun 4 Ruby [![Build Status](https://travis-ci.org/MindscapeHQ/raygun4ruby.png?branch=master)](https://travis-ci.org/MindscapeHQ/raygun4ruby)

This is the Ruby adapter for the Raygun error reporter, http://raygun.io.


## Installation

Add this line to your application's Gemfile:

    gem 'raygun4ruby'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install raygun4ruby

## Usage

###Rails 3/4

Run:

    rails g raygun:install YOUR_API_KEY_HERE

You can find your API key on your [Raygun Dashboard](https://app.raygun.io/dashboard/)

You can then test your Raygun integration by running:

    rake raygun:test

You should see an "ItWorksException" appear in your Raygun dashboard. You're ready to zap those errors!

NB: Raygun4Ruby currently requires Ruby >= 1.9

Note that the generator will create a file in `config/initializers` called "raygun.rb". If you need to do any further configuration or customization of Raygun, that's the place to do it!

### Rails 2

Raygun4Ruby doesn't currently support Rails 2. If you'd like Rails 2 support, [drop us a line](http://raygun.io/forums).

###Standalone / Manual Exception Tracking

```ruby

require 'rubygems'
require 'raygun4ruby'

Raygun.setup do |config|
  config.api_key = "YOUR_RAYGUN_API_KEY"
end

begin
  # your lovely code here
rescue Exception => e
  Raygun.track_exception(e)
end

```

(You can also pass a Hash as the second parameter to `track_exception`. It should look like a [Rack Env Hash](http://rack.rubyforge.org/doc/SPEC.html))

###Custom User Data
Custom data can be added to `track_exception` by passing a custom_data key in the second parameter hash.

```ruby

begin
  # more lovely code
rescue Exception => e
  Raygun.track_exception(e, custom_data: {my: 'custom data', goes: 'here'})
end

```

###Ignoring Some Errors

You can ignore certain types of Exception using the `ignore` option in the setup block, like so:

```ruby
Raygun.setup do |config|
  config.api_key = "MY_SWEET_API_KEY"
  config.ignore  << [MyApp::AnExceptionIDontCareAbout]
end
```

You can also check which [exceptions are ignored by default](https://github.com/MindscapeHQ/raygun4ruby/blob/master/lib/raygun/configuration.rb#L26)

###Affected User Tracking

Raygun can now track how many users have been affected by an error.

By default, Raygun looks for a method called `current_user` on your controller, and calls either `email`, `username` or `id` on the object returned by that method. 

You can customize those method names in your configuration block:

```ruby
Raygun.setup do |config|
  config.api_key = "MY_SWEET_API_KEY"
  config.affected_user_method = :my_current_user # `current_user` by default
  config.affected_user_identifier_methods << :login # `[ :email, :username, :id ]` by default - will use the first that works
end
```

If you're using Rails, most authentication systems will have this method set and you should be good to go.

The count of unique affected users will appear on the error group in the Raygun dashboard. If your user has an `email` method, and that email has a Gravatars associated, you will also see your user's avatar. 

If you wish to keep it anonymous, you could set this identifier to something like `SecureRandom.uuid` and store that in a cookie, like so:

```ruby
class ApplicationController < ActionController::Base
 
  def raygun_user
    cookies.permanent[:raygun_user_identifier] ||= SecureRandom.uuid
  end

end
```

(Remember to set `affected_user_method` to `:raygun_user` in your config block...)

###Resque Error Tracking

Raygun4Ruby also includes a Resque failure backend. You should include it inside your Resque initializer (usually something like `config/initializers/load_resque.rb`)

```ruby
require 'resque/failure/multiple'
require 'resque/failure/raygun'
require 'resque/failure/redis'

Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Raygun]
Resque::Failure.backend = Resque::Failure::Multiple
```

## Found a bug?

Oops! Just let us know by opening an Issue on Github.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
