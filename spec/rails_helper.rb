ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'

require 'dummy/config/environment'

require 'rspec/rails'

ActiveRecord::Migration.maintain_test_schema!

#Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

# set up db
# be sure to update the schema if required by doing
# - cd spec/dummy
# - rake db:migrate
ActiveRecord::Schema.verbose = false
load 'dummy/db/schema.rb' # use db agnostic schema by default


