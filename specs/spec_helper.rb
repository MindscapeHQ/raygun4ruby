ENV['RACK_ENV'] = 'test'
require_relative "../lib/raygun.rb"
require "minitest/autorun"
require "minitest/pride"
require "fakeweb"
require "timecop"
require "mocha/mini_test"
require "webmock/minitest"

alias :context :describe
