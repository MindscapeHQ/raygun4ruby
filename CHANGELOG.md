## 3.1.1 (16/01/2019):
Bugfix:
  - Don't attempt to modify response unless JS api key is present
  - Don't attempt to modify response unless it responds to indexing ([])
  - See PR ([#140](https://github.com/MindscapeHQ/raygun4ruby/pull/140))

## 3.1.0 (15/01/2019):

Feature:  
    - Ability to automatically configure Raygun4JS on the client side by injecting it into outbound HTML pages. Thanks @MikeRogers0 for this ([#138](https://github.com/MindscapeHQ/raygun4ruby/pull/138))

## 3.0.0 (18/12/2018):
  Breaking changes:
    Parameter filters are now applied if you are using the `filter_payload_with_whitelist` functionality. Previously if this was set to true the parameter filtering was bailed out of ([#136](https://github.com/MindscapeHQ/raygun4ruby/pull/136/files))

## 2.7.1 (11/06/2018)
  This is a patch release to update the required ruby version to correctly be 2.0 or greater

## 2.7.0 (19/02/2018)

Features
 - Add configuration option to control network timeouts when sending error reports, default value is 10 seconds ([#129](https://github.com/MindscapeHQ/raygun4ruby/pull/129))

## 2.6.0 (25/10/2017)

Features
  - Enhanced debug logging to assist in resolving issues from support requests ([#128](https://github.com/MindscapeHQ/raygun4ruby/pull/128))

## 2.5.0 (04/10/2017)

Features
  - Teach tags configuration how to handle a proc to allow dynamically settings tags ([#127](https://github.com/MindscapeHQ/raygun4ruby/pull/127))

Bugfixes
  - Fix crash when recording breadcrumb with uninitialized store ([#126](https://github.com/MindscapeHQ/raygun4ruby/pull/126))
  - Make raw data handling more robust and fix in unicorn ([#125](https://github.com/MindscapeHQ/raygun4ruby/pull/125))
  - Backwards compatible affected_user_identifier_methods ([#120](https://github.com/MindscapeHQ/raygun4ruby/pull/120))

## 2.4.1 (29/08/2017)

Bugfixes
  - Fix crash in `Client#raw_data` method when `rack.input` buffer is missing `pos` method

## 2.4.0 (31/07/2017)

Features
  - Add functionality to track affected user in Sidekiq jobs, refer to the README for more information, under the "Affected User Tracking in Sidekiq" heading ([#121](https://github.com/MindscapeHQ/raygun4ruby/pull/121))

## 2.3.0 (09/05/2017)"

Bugfixes
  - Fix issue preventing affected users for a crash report from showing up in the affected users page ([#119](https://github.com/MindscapeHQ/raygun4ruby/pull/119))

## 2.2.0 (05/05/2017)

Features
  - Opt in support for sending exceptions in a background thread to not block web request thread during IO ([#117](https://github.com/MindscapeHQ/raygun4ruby/pull/117))

Bugfixes
 - Don't attempt to read raw data during GET requests or if rack.input buffer is empty

## 2.1.0 (27/04/2017)

Features
  - Ability to record breadcrumbs in your code that will be sent to Raygun along with a raised exception ([#113](https://github.com/MindscapeHQ/raygun4ruby/pull/113))

## 2.0.0 (20/04/2017)

Bugfixes:
  - Fix broken handling of raw request body reading in Rack applications ([#116](https://github.com/MindscapeHQ/raygun4ruby/pull/116))
    - This is a breaking change to how raw data was being read before so it requires a major version bump
    - Raw request data reading is now disabled by default and can be enabled via the `record_raw_data` configuration option
    
Since this is a major version bump this release also deprecates ruby versions < 2.0

## 1.5.0 (16/03/2017)

Features
  - Send utcOffset with Raygun payload to calculate local server time in Raygun dashboard ([#112](https://github.com/MindscapeHQ/raygun4ruby/pull/112))

## 1.4.0 (14/03/2017)

Features:
  - Raygun API url is now configurable via `Configuration.api_url` ([#111](https://github.com/MindscapeHQ/raygun4ruby/pull/111))
  - Added support for `Exception#cause` to be tracked as `innerError` on Raygun. Only supported on Ruby >= 2.1 ([#107](https://github.com/MindscapeHQ/raygun4ruby/pull/107))

## 1.3.0 (10/03/2017)

Features:
  - Improve affected user handling to let you specify all Raygun parameters, identifier, email, first name, full name and uuid. See [README.md](https://github.com/MindscapeHQ/raygun4ruby#affected-user-tracking) for details ([#34](https://github.com/MindscapeHQ/raygun4ruby/pull/34))
  - Pass a user object as the third parameter to `Raygun.track_exception` to have affected user tracking for manually tracked exceptions, see the above link for more information on configuring this ([#106](https://github.com/MindscapeHQ/raygun4ruby/pull/106))
  - If the exception instance responds to `:raygun_custom_data` that method will be called and the return value merged into the `custom_data` hash sent to Raygun. For convenience a `Raygun::Error` class is provided that takes this custom data as a second argument ([#101](https://github.com/MindscapeHQ/raygun4ruby/pull/101))
  - Allowed `Configuration.custom_data` to be set to a proc to allow a global custom data hook for all exceptions. It is passed as arguments the exception and the environment hash ([#108](https://github.com/MindscapeHQ/raygun4ruby/pull/108))
  - Added `Configuration.debug` to enable logging the reason why an exception was not reported ([#109](https://github.com/MindscapeHQ/raygun4ruby/pull/109))

## 1.2.1 (09/03/2017)

Bugfixes:
  - dup input hashes before applying whitelist filtering, previously this was modifying the contents of `action_dispatch.request.parameters` ([#105](https://github.com/MindscapeHQ/raygun4ruby/pull/105))

## 1.2.0 (09/03/2017)

Features:
  - Added two new configuration options, `filter_payload_with_whitelist` and `whitelist_payload_shape` ([#100](https://github.com/MindscapeHQ/raygun4ruby/pull/100))
    - See [README.md](https://github.com/MindscapeHQ/raygun4ruby#filtering-the-payload-by-whitelist) for an example of how to use them
  - When raygun4ruby encounters an exception trying to track an exception it will try once to send that exception to Raygun so you are notified ([#104](https://github.com/MindscapeHQ/raygun4ruby/pull/104))

Bugfixes:
  - raygun4ruby will no longer crash and suppress app exceptions when the API key is not configured ([#87](https://github.com/MindscapeHQ/raygun4ruby/pull/87))
