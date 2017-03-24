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
          Store.initialize_store
        end
        after do
          Timecop.return
          Store.clear_store
        end

        let(:breadcrumb) do
          Store.record do |c|
            c.message = "test"
            c.category = "test"
            c.level = "info"
            c.class_name = "HomeController"
            c.method_name = "index"
            c.line_number = 17
            c.metadata = {
              foo: 'bar'
            }
          end

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

        it "includes the rest of the fields" do
          payload[:message].must_equal("test")
          payload[:category].must_equal("test")
          payload[:level].must_equal("info")
          payload[:timestamp].must_equal(Time.now.utc)
          payload[:data].must_equal({
            foo: 'bar'
          })
        end
      end
    end
  end
end
