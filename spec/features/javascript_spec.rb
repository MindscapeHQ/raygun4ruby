require 'rails_helper'

feature 'JavaScript Tracking', feature: true do

  it "No JS snippet is injected" do
    expect(Rails.application.config.middleware).to include(Raygun::Middleware::Javascript)
    visit root_path

    expect(page.html).to_not include("<script type=\"text/javascript\">!function(a,b,c,d,e,f,g,h){a.RaygunObject=e,a[e]=a[e]||function(){(a[e].o=a[e].o||[]).push(arguments)},f=b.createElement(c),g=b.getElementsByTagName(c)[0],f.async=1,f.src=d,g.parentNode.insertBefore(f,g),h=a.onerror,a.onerror=function(b,c,d,f,g){h&&h(b,c,d,f,g),g||(g=new Error(b)),a[e].q=a[e].q||[],a[e].q.push({e:g})}}(window,document,\"script\",\"//cdn.raygun.io/raygun4js/raygun.min.js\",\"rg4js\");</script></head>")
    expect(page.html).to_not include("<script type=\"text/javascript\">rg4js('apiKey', '');rg4js('enableCrashReporting', true);rg4js('setUser', { identifier: '1' });</script></body>")
  end

  context 'With a JS API Key' do
    before { Raygun.configuration.js_api_key = 'Sample key' }
    after { Raygun.configuration.js_api_key = nil }

    it "JS snippet is injected" do
      expect(Rails.application.config.middleware).to include(Raygun::Middleware::Javascript)
      visit root_path

      expect(page.html).to include("<script type=\"text/javascript\">!function(a,b,c,d,e,f,g,h){a.RaygunObject=e,a[e]=a[e]||function(){(a[e].o=a[e].o||[]).push(arguments)},f=b.createElement(c),g=b.getElementsByTagName(c)[0],f.async=1,f.src=d,g.parentNode.insertBefore(f,g),h=a.onerror,a.onerror=function(b,c,d,f,g){h&&h(b,c,d,f,g),g||(g=new Error(b)),a[e].q=a[e].q||[],a[e].q.push({e:g})}}(window,document,\"script\",\"//cdn.raygun.io/raygun4js/raygun.min.js\",\"rg4js\");</script></head>")
      expect(page.html).to include("<script type=\"text/javascript\">rg4js('apiKey', '');rg4js('enableCrashReporting', true);rg4js('setUser', { identifier: '1' });</script></body>")
    end
  end
end
