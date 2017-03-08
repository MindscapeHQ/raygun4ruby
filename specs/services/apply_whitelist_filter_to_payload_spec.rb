require "minitest/autorun"
require "minitest/pride"
require_relative "../../lib/raygun"

module Raygun
  module Services
    describe ApplyWhitelistFilterToPayload do
      let(:service) { ApplyWhitelistFilterToPayload.new }

      describe "top level keys" do
        let(:payload) do
          { foo: 1, bar: 2 }
        end
        let(:expected) do
          { foo: 1 , bar: '[FILTERED]'}
        end

        it "filters out keys that are not present in the shape" do
          shape = {
            foo: true
          }

          new_payload = service.call(shape, payload)

          new_payload.must_equal(expected)
        end

        it "filters out keys that are set to false" do
          shape = {
            foo: true,
            bar: false
          }

          new_payload = service.call(shape, payload)

          new_payload.must_equal(expected)
        end
      end

      describe "nested hashes" do
        let(:payload) {{
          foo: 1,
          bar: {
            baz: 2,
            qux: 3
          }
        }}
        let(:expected) {{
          foo: 1,
          bar: {
            baz: 2,
            qux: '[FILTERED]'
          }
        }}

        it "filters out keys in nested hashes" do
          shape = {
            foo: true,
            bar: {
              baz: true
            }
          }

          new_payload = service.call(shape, payload)

          new_payload.must_equal(expected)
        end

        it "filters out a nested hash if the whitelist does not contain it" do
          shape = {
            foo: true
          }
          expected[:bar] = "[FILTERED]"

          new_payload = service.call(shape, payload)

          new_payload.must_equal(expected)
        end

        it "handles nested hashes when the whitelist is set to allow the whole hash" do
          shape = {
            bar: true
          }
          expected = {
            foo: '[FILTERED]',
            bar: {
              baz: 2,
              qux: 3
            }
          }

          new_payload = service.call(shape, payload)

          new_payload.must_equal(expected)
        end

        it "handles nested hashes when the whitelist is set to not allow the whole hash" do
          shape = {
            foo: true,
            bar: false
          }
          expected = {
            foo: 1,
            bar: '[FILTERED]'
          }

          new_payload = service.call(shape, payload)

          new_payload.must_equal(expected)
        end
      end

      describe "string keys" do
        it "handles the case where a payload key is a string and a whitelist key is a symbol" do
          shape = {
            foo: true
          }
          payload = {
            "foo" => 1,
            "bar" => 2
          }
          expected = {
            "foo" => 1,
            "bar" => '[FILTERED]'
          }

          new_payload = service.call(shape, payload)

          new_payload.must_equal(expected)
        end
      end

      it "handles a very complex shape" do
        shape = {
          machineName: true,
          version: true,
          client: true,
          error: {
            className: true,
            message: true,
            stackTrace: true
          },
          userCustomData: true,
          tags: true,
          request: {
            hostName: true,
            url: true,
            httpMethod: true,
            iPAddress: true,
            queryString: {
              param1: true,
              param2: true,
            },
            headers: {
              "Host" => true,
              "Connection" => true,
              "Upgrade-Insecure_requests" => true,
              "User-Agent" => false,
              "Accept" => true,
            },
            form: {
              controller: true,
              action: false
            },
            rawData: {
              controller: true,
              action: false
            }
          },
          user: false,
        }
        payload = {
          machineName: "mindscapes-MacBook-Pro.local",
          version: nil,
          client: {name: "Raygun4Ruby Gem", version: "1.1.12", clientUrl: "https://github.com/MindscapeHQ/raygun4ruby"},
          error: {className: "Exception", message: "foo", stackTrace: []},
          userCustomData: {},
          tags: ["development"],
          request: {
            hostName: "localhost",
            url: "/make-me-an-error-charlie",
            httpMethod: "GET",
            iPAddress: "::1",
            queryString: {
              param1: "1",
              param2: "2",
              param3: "3",
            },
            headers: {
              "Host"=>"localhost:3000",
              "Connection"=>"keep-alive",
              "Upgrade-Insecure_requests"=>"1",
              "User-Agent"=> "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36",
              "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
              "Accept-Encoding"=>"gzip, deflate, sdch, br",
              "Accept-Language"=>"en-US,en;q=0.8",
              "Version"=>"HTTP/1.1"
            },
            form: {
              controller: "home",
              action: "raise_error"
            },
            rawData: {
              controller: "home",
              action: "raise_error"
            }
          }
        }
        expected = {
          machineName: "mindscapes-MacBook-Pro.local",
          version: nil,
          client: {name: "Raygun4Ruby Gem", version: "1.1.12", clientUrl: "https://github.com/MindscapeHQ/raygun4ruby"},
          error: {className: "Exception", message: "foo", stackTrace: []},
          userCustomData: {},
          tags: ["development"],
          request: {
            hostName: "localhost",
            url: "/make-me-an-error-charlie",
            httpMethod: "GET",
            iPAddress: "::1",
            queryString: {
              param1: "1",
              param2: "2",
              param3: '[FILTERED]'
            },
            headers: {
              "Host"=>"localhost:3000",
              "Connection"=>"keep-alive",
              "Upgrade-Insecure_requests"=>"1",
              "User-Agent" => "[FILTERED]",
              "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
              "Accept-Encoding" => "[FILTERED]",
              "Accept-Language" => "[FILTERED]",
              "Version" => "[FILTERED]"
            },
            form: {
              controller: "home",
              action: "[FILTERED]"
            },
            rawData: {
              controller: "home",
              action: "[FILTERED]"
            }
          }
        }

        new_payload = service.call(shape, payload)

        new_payload.must_equal(expected)
      end
    end
  end
end
