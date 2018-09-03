module Raygun
  # client for the Raygun REST APIv1
  # as per http://raygun.io/raygun-providers/rest-json-api?v=1
  class JsTracker

    NO_API_KEY_MESSAGE  = "[RAYGUN] Just a note, you don't have a JS API Key configured, which means we can't report exceptions. Specify your Raygun API key using Raygun#setup (find yours at https://app.raygun.io)"

    def initialize
      @js_api_key = require_js_api_key
    end

    def require_js_api_key
      Raygun.configuration.js_api_key || print_js_api_key_warning
    end

    def head_html
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
      [
        '<script type="text/javascript">',
        "rg4js('apiKey', '#{@js_api_key}');",
        "rg4js('enableCrashReporting', true);",
        user_tracking,
        '</script>'
      ].join('').html_safe
    end

    private

    def user_tracking
      # TODO, Pull in user data from somewhere.
      "rg4js('setUser', { identifier: '1' });"
    end

    def require_js_api_key
      $stderr.puts(NO_API_KEY_MESSAGE)
    end
  end
end
