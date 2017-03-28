require "minitest/autorun"
require "minitest/pride"
require_relative "../../spec_helper"

module Raygun
  module Breadcrumbs
    describe Store do
      let(:subject) { Store }
      after { subject.clear }

      describe "#initialize" do
        before do
          subject.stored.must_equal(nil)

          subject.initialize
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
        it "returns true if any breadcrumbs have been logged" do
          subject.initialize

          subject.record(message: "test")

          subject.any?.must_equal(true)
        end

        it "returns false if none have been logged" do
          subject.initialize

          subject.any?.must_equal(false)
        end

        it "returns false if the store is uninitialized" do
          subject.any?.must_equal(false)
        end
      end

      describe "#clear" do
        before do
          subject.initialize
        end

        it "resets the store back to nil" do
          subject.clear

          subject.stored.must_equal(nil)
        end
      end

      describe "#should_record?" do
        it "returns false when the log level is above the breadcrumbs level" do
          Raygun.configuration.stubs(:breadcrumb_level).returns(:error)

          crumb = Breadcrumb.new
          crumb.level = :warning

          assert_equal false, subject.send(:should_record?, crumb)
        end
      end

      context "adding a breadcrumb" do
        class Foo
          include ::Raygun::Breadcrumbs

          def bar
            record_breadcrumb(message: "test")
          end
        end

        before do
          subject.clear
          subject.initialize
        end

        it "gets stored" do
          subject.record(message: "test")

          subject.stored.length.must_equal(1)
          subject.stored[0].message.must_equal("test")
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
          subject.record(message: 'test', method_name: "foo")

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
            subject.record(message: 'test', timestamp: time)

            subject.stored[0].timestamp.wont_equal(Time.now.utc)
          end
        end

        it "sets the log level to :info if one is not supplied" do
          Foo.new.bar

          subject.stored[0].level.must_equal(:info)
        end

        it "does not record the breadcrumb if should_record? is false" do
          subject.stubs(:should_record?).returns(false)
          Foo.new.bar

          subject.stored.length.must_equal(0)
        end
      end
    end
  end
end
