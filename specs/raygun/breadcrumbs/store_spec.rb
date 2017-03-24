require "minitest/autorun"
require "minitest/pride"
require_relative "../../spec_helper"

module Raygun
  module Breadcrumbs
    describe Store do
      let(:subject) { Store }

      describe "#initialize_store" do
        before do
          subject.stored.must_equal(nil)

          subject.initialize_store
        end

        after do
          subject.clear_store
        end

        it "creates the store on the current Thread" do
          subject.stored.must_equal([])
        end

        it "does not effect other threads" do
          Thread.new do
            subject.stored.must_equal(nil)
          end.join
        end
      end

      describe "any?" do
        after { subject.clear_store }

        it "returns true if any breadcrumbs have been logged" do
          subject.initialize_store

          subject.record do |c|
            c.message = "test"
          end

          subject.any?.must_equal(true)
        end

        it "returns false if none have been logged" do
          subject.initialize_store

          subject.any?.must_equal(false)
        end

        it "returns false if the store is uninitialized" do
          subject.any?.must_equal(false)
        end
      end

      describe "#clear_store" do
        before do
          subject.initialize_store
        end

        it "resets the store back to nil" do
          subject.clear_store

          subject.stored.must_equal(nil)
        end
      end

      context "adding a breadcrumb" do
        class Foo
          include ::Raygun::Breadcrumbs

          def bar
            record_breadcrumb do |crumb|
              crumb.message = "test"
            end
          end
        end

        before do
          subject.clear_store
          subject.initialize_store
        end

        it "gets stored" do
          subject.record do |crumb|
            crumb.message = "test"
          end

          subject.stored.length.must_equal(1)
          subject.stored[0].message.must_equal("test")
        end

        it "lets you pass in a pre constructed breadcrumb" do
          breadcrumb = Breadcrumb.new
          breadcrumb.category = "test"

          subject.record(breadcrumb) do |crumb|
            crumb.message = "test"
          end

          bc = subject.stored[0]
          bc.category.must_equal("test")
          bc.message.must_equal("test")
        end

        it "automatically sets the class name" do
          Foo.new.bar

          bc = subject.stored[0]
          bc.class_name.must_equal("Raygun::Breadcrumbs::Foo")
        end

        it "automatically sets the method name" do
          Foo.new.bar

          bc = subject.stored[0]
          bc.method_name.must_equal("bar")
        end

        it "does not set the method name if it is already set" do
          subject.record do |crumb|
            crumb.method_name = "foo"
          end

          subject.stored[0].method_name.must_equal("foo")
        end


        it "automatically sets the timestamp" do
          Timecop.freeze do
            Foo.new.bar

            bc = subject.stored[0]
            bc.timestamp.must_equal(Time.now.utc)
          end
        end

        it "does not set the timestamp if it is already set" do
          time = Time.now.utc

          Timecop.freeze do
            subject.record do |crumb|
              crumb.timestamp = time
            end

            subject.stored[0].timestamp.wont_equal(Time.now.utc)
          end
        end
      end
    end
  end
end
