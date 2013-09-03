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

###Ignoring Some Errors

You can ignore certain types of Exception using the `ignore` option in the setup block, like so:

```ruby
Raygun.setup do |config|
  config.api_key = "MY_SWEET_API_KEY"
  config.ignore  << [MyApp::AnExceptionIDontCareAbout]
end
```

You can also check which [exceptions are ignored by default](https://github.com/MindscapeHQ/raygun4ruby/blob/master/lib/raygun/configuration.rb#L26)

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
