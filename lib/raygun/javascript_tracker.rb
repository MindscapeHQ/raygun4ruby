# Client for injecting JavaScript code for tracking front end exceptions
# https://raygun.com/docs/languages/javascript
module Raygun
  class JavaScriptTracker
    def head_html
      return unless js_api_key?
      [
        '<script type="text/javascript">',
        '!function(a,b,c,d,e,f,g,h){a.RaygunObject=e,a[e]=a[e]||function(){',
        '(a[e].o=a[e].o||[]).push(arguments)},f=b.createElement(c),g=b.getElementsByTagName(c)[0],',
        'f.async=1,f.src=d,g.parentNode.insertBefore(f,g),h=a.onerror,a.onerror=function(b,c,d,f,g){',
        'h&&h(b,c,d,f,g),g||(g=new Error(b)),a[e].q=a[e].q||[],a[e].q.push({',
        'e:g})}}(window,document,"script","//cdn.raygun.io/raygun4js/raygun.min.js","rg4js");',
        '</script>'
      ].join('').html_safe
    end

    def body_html
      return unless js_api_key?
      [
        '<script type="text/javascript">',
        "rg4js('apiKey', '#{js_api_key}');",
        "rg4js('enableCrashReporting', true);",
        '</script>'
      ].join('').html_safe
    end

    private

    def js_api_key
      @js_api_key ||= Raygun.configuration.js_api_key
    end

    def js_api_key?
      js_api_key.present?
    end
  end
end
