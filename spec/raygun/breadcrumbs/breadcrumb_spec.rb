require "spec_helper"

module Raygun
  module Breadcrumbs
    describe Breadcrumb do
      let(:subject) { Breadcrumb.new }
      context 'fields' do
        it 'has a message' do
          message = 'foo'

          subject.message = message

          expect(subject.message).to eq(message)
        end

        it 'has a category' do
          category = 'foo'

          subject.category = category

          expect(subject.category).to eq(category)
        end

        it 'has a level' do
          level = 'foo'

          subject.level = level

          expect(subject.level).to eq(level)
        end

        it 'has a timestamp' do
          timestamp = Time.now

          subject.timestamp = timestamp

          expect(subject.timestamp).to eq(timestamp)
        end

        it 'has metadata' do
          metadata = {foo: '1'}

          subject.metadata = metadata

          expect(subject.metadata).to eq(metadata)
        end

        it 'has a class_name' do
          class_name = 'foo'

          subject.class_name = class_name

          expect(subject.class_name).to eq(class_name)
        end

        it 'has a method_name' do
          method_name = 'foo'

          subject.method_name = method_name

          expect(subject.method_name).to eq(method_name)
        end

        it 'has a line_number' do
          line_number = 17

          subject.line_number = line_number

          expect(subject.line_number).to eq(line_number)
        end
      end

      describe "#build_payload" do
        before do
          Timecop.freeze
          Store.initialize
        end
        after do
          Timecop.return
          Store.clear
        end

        let(:breadcrumb) do
          Store.record(
            message: "test",
            category: "test",
            level: :info,
            class_name: "HomeController",
            method_name: "index",
            line_number: 17,
            metadata: {
              foo: 'bar'
            }
          )

          Store.stored[0]
        end
        let(:payload) { breadcrumb.build_payload }

        it "joins the class name, method name and line number together" do
          expect(payload[:location]).to eq("HomeController:index:17")
        end

        it "does not include the method name and line number if the class name is missing" do
          breadcrumb.class_name = nil

          expect(payload.has_key?(:location)).to eq(false)
        end

        it "does not inlcude the line number if is it missing" do
          breadcrumb.line_number = nil

          expect(payload[:location]).to eq("HomeController:index")
        end

        it "does not include keys in payload with nil values" do
          breadcrumb.metadata = nil
          breadcrumb.category = nil

          expect(payload.key?(:CustomData)).to eq(false)
          expect(payload.key?(:category)).to eq(false)
        end

        it 'includes the rest of the fields' do
          expect(payload[:message]).to eq('test')
          expect(payload[:category]).to eq('test')
          expect(payload[:level]).to eq(1)
          expect(payload[:timestamp]).to_not eq(nil)
          expect(payload[:CustomData]).to eq(foo: 'bar')
        end
      end

      describe "#size" do
        before do
          Timecop.freeze
          Store.initialize
        end
        after do
          Timecop.return
          Store.clear
        end

        let(:message) { "This is a breadcrumb message" }

        let(:breadcrumb) do
          Store.record(
            message: message,
            category: "test",
            level: :info,
            class_name: "HomeController",
            method_name: "index",
            line_number: 17,
            metadata: {
              foo: 'bar'
            }
          )

          Store.stored[0]
        end

        let(:size) { breadcrumb.size }

        it "returns the estimated size of the breadcrumb" do
          # Can't check all the fields but message so assume a standard 100 length for all of them
          # The message should be the bulk of large breadcrumbs anyway
          expect(size).to eq(message.length + 100)
        end
      end
    end
  end
end
