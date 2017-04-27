require_relative "../../spec_helper"

module Raygun
  module Breadcrumbs
    describe Breadcrumb do
      let(:subject) { Breadcrumb.new }
      context 'fields' do
        it 'has a message' do
          message = 'foo'

          subject.message = message

          subject.message.must_equal(message)
        end

        it 'has a category' do
          category = 'foo'

          subject.category = category

          subject.category.must_equal(category)
        end

        it 'has a level' do
          level = 'foo'

          subject.level = level

          subject.level.must_equal(level)
        end

        it 'has a timestamp' do
          timestamp = Time.now

          subject.timestamp = timestamp

          subject.timestamp.must_equal(timestamp)
        end

        it 'has metadata' do
          metadata = {foo: '1'}

          subject.metadata = metadata

          subject.metadata.must_equal(metadata)
        end

        it 'has a class_name' do
          class_name = 'foo'

          subject.class_name = class_name

          subject.class_name.must_equal(class_name)
        end

        it 'has a method_name' do
          method_name = 'foo'

          subject.method_name = method_name

          subject.method_name.must_equal(method_name)
        end

        it 'has a line_number' do
          line_number = 17

          subject.line_number = line_number

          subject.line_number.must_equal(line_number)
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
          payload[:location].must_equal("HomeController:index:17")
        end

        it "does not include the method name and line number if the class name is missing" do
          breadcrumb.class_name = nil

          payload.has_key?(:location).must_equal(false)
        end

        it "does not inlcude the line number if is it missing" do
          breadcrumb.line_number = nil

          payload[:location].must_equal("HomeController:index")
        end

        it "does not include keys in payload with nil values" do
          breadcrumb.metadata = nil
          breadcrumb.category = nil

          payload.key?(:CustomData).must_equal(false)
          payload.key?(:category).must_equal(false)
        end

        it 'includes the rest of the fields' do
          payload[:message].must_equal('test')
          payload[:category].must_equal('test')
          payload[:level].must_equal(1)
          payload[:timestamp].wont_be_nil
          payload[:CustomData].must_equal(foo: 'bar')
        end
      end
    end
  end
end
