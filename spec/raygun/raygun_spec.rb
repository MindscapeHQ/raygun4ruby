require 'spec_helper'

describe Raygun do
  let(:failsafe_logger) { FakeLogger.new }

  describe '#track_exception' do
    context 'send in background' do
      before do
        Raygun.setup do |c|
          c.silence_reporting = false
          c.send_in_background = true
          c.api_url = 'http://example.api'
          c.api_key = 'foo'
          c.debug = true
          c.failsafe_logger = failsafe_logger
        end
      end

      context 'request times out' do
        before do
          stub_request(:post, 'http://example.api/entries').to_timeout
        end

        it 'logs the failure to the failsafe logger' do
          error = StandardError.new

          Raygun.track_exception(error)

          # Occasionally doesn't write to the failsafe logger, add small timeout to add some safety
          sleep 0.1
          expect(failsafe_logger.get).to match /Problem reporting exception to Raygun/
        end
      end
    end
  end

  describe '#reset_configuration' do
    subject { Raygun.reset_configuration }
    it 'clears any customized configuration options' do
      Raygun.setup do |c|
        c.api_url = 'http://test.api'
      end

      expect { subject }.to change { Raygun.configuration.api_url }.from('http://test.api').to(Raygun.default_configuration.api_url)
    end
  end

  describe "error subscriber" do
    before do
      Raygun.setup do |c|
        c.api_key = "test"
        c.silence_reporting = false
        c.debug = true
        c.register_rails_error_handler = true
      end

      Raygun::Railtie.setup_error_subscriber
    end

    if ::Rails.version.to_f >= 7.0
      it "registers with rails" do
        expect(Rails.error.instance_variable_get("@subscribers")).to include(a_kind_of(Raygun::ErrorSubscriber))
      end

      it "reports exceptions" do
        stub_request(:post, "https://api.raygun.com/entries").to_return(status: 202)

        Rails.error.handle do
          raise StandardError.new("test rails handling")
        end
      end
    end
  end
end
