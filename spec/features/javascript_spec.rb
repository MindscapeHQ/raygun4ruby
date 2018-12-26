require 'rails_helper'

feature 'JavaScript Tracking', feature: true do
  before { Raygun.configuration.js_api_key = nil }
  after { Raygun.configuration.js_api_key = nil }

  it "Includes the Raygun Javascript Middleware" do
    expect(Rails.application.config.middleware).to include(Raygun::Middleware::JavascriptExceptionTracking)
  end

  it "Does not inject the JS snippet" do
    visit root_path

    expect(page.html).to_not include('cdn.raygun.io/raygun4js/1.14.0/raygun.min.js')
  end

  context 'With a JS API Key' do
    before { Raygun.configuration.js_api_key = 'Sample key' }

    it "Injects the JS snippet" do
      visit root_path

      expect(page.html).to include('cdn.raygun.io/raygun4js/1.14.0/raygun.min.js')
    end

    it "Does not inject the JS snippet" do
      visit root_path(format: :json)

      expect(page.html).to_not include('cdn.raygun.io/raygun4js/1.14.0/raygun.min.js')
    end
  end
end
