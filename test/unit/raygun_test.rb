# -*- coding: utf-8 -*-
require_relative "../test_helper.rb"
require 'stringio'

class RaygunTest < Raygun::UnitTest

  def test_raygun_is_not_configured_with_no_api_key
    Raygun.configuration.api_key = nil
    assert !Raygun.configured?
  end

end
