## 2.2.0

Features
  - Opt in support for sending exceptions in a background thread to not block web request thread during IO ([#117](https://github.com/MindscapeHQ/raygun4ruby/pull/117))

Bugfixes
 - Don't attempt to read raw data during GET requests or if rack.input buffer is empty

## 2.1.0

Features
  - Ability to record breadcrumbs in your code that will be sent to Raygun along with a raised exception ([#113](https://github.com/MindscapeHQ/raygun4ruby/pull/113))

## 2.0.0 (20/04/2017)

Bugfixes:
  - Fix broken handling of raw request body reading in Rack applications ([#116](https://github.com/MindscapeHQ/raygun4ruby/pull/116))
    - This is a breaking change to how raw data was being read before so it requires a major version bump
    - Raw request data reading is now disabled by default and can be enabled via the `record_raw_data` configuration option

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
