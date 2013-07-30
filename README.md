# Raygun 4 Ruby

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

###Standalone / Manual Exception Tracking

```ruby

require 'rubygems'
require 'raygun4ruby'

begin
  # your lovely code here
rescue Exception => e
  Raygun.track_exception(e)
end

```

(You can also pass a Hash as the second parameter to `track_exception`. It should look like a [Rack Env Hash](http://rack.rubyforge.org/doc/SPEC.html))

## Found a bug?

Oops! Just let us know by opening an Issue on Github.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
