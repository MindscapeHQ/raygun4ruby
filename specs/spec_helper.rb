ENV['RACK_ENV'] = 'test'
require_relative "../lib/raygun.rb"
require "minitest/autorun"
require "minitest/pride"
require "fakeweb"
require "timecop"
require "mocha/mini_test"
require "webmock/minitest"
require 'stringio'

alias :context :describe

class FakeLogger
  def initialize
    @logger = StringIO.new
  end

  def info(message)
    @logger.write(message)
  end

  def reset
    @logger.string = ""
  end

  def get
    @logger.string
  end
end

