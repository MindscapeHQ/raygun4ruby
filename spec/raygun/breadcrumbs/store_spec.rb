require "spec_helper"

module Raygun
  module Breadcrumbs
    describe Store do
      let(:subject) { Store }
      after { subject.clear }

      describe "#initialize" do
        before do
          expect(subject.stored).to eq(nil)

          subject.initialize
        end

        it "creates the store on the current Thread" do
          expect(subject.stored).to eq([])
        end

        it "does not effect other threads" do
          Thread.new do
            expect(subject.stored).to eq(nil)
          end.join
        end
      end

      describe "#any?" do
        it "returns true if any breadcrumbs have been logged" do
          subject.initialize

          subject.record(message: "test")

          expect(subject.any?).to eq(true)
        end

        it "returns false if none have been logged" do
          subject.initialize

          expect(subject.any?).to eq(false)
        end

        it "returns false if the store is uninitialized" do
          expect(subject.any?).to eq(false)
        end
      end

      describe "#clear" do
        before do
          subject.initialize
        end

        it "resets the store back to nil" do
          subject.clear

          expect(subject.stored).to eq(nil)
        end
      end

      describe "#should_record?" do
        it "returns false when the log level is above the breadcrumbs level" do
          allow(Raygun.configuration).to receive(:breadcrumb_level).and_return(:error)

          crumb = Breadcrumb.new
          crumb.level = :warning

          expect(subject.send(:should_record?, crumb)).to eq(false)
        end
      end

      describe "#take_until_size" do
        before do
          subject.initialize
        end

        it "takes the most recent breadcrumbs until the size limit is reached" do
          subject.record(message: '1' * 100)
          subject.record(message: '2' * 100)
          subject.record(message: '3' * 100)

          crumbs = subject.take_until_size(500)

          expect(crumbs.length).to eq(2)
          expect(crumbs[0].message).to eq('2' * 100)
          expect(crumbs[1].message).to eq('3' * 100)
        end

        it "does not crash with no recorded breadcrumbs" do
          crumbs = subject.take_until_size(500)

          expect(crumbs).to eq([])
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

          expect(subject.stored.length).to eq(1)
          expect(subject.stored[0].message).to eq("test")
        end

        it "automatically sets the class name" do
          Foo.new.bar

          bc = subject.stored[0]
          expect(bc.class_name).to eq("Raygun::Breadcrumbs::Foo")
        end

        it "automatically sets the method name" do
          Foo.new.bar

          bc = subject.stored[0]
          expect(bc.method_name).to eq("bar")
        end

        it "does not set the method name if it is already set" do
          subject.record(message: 'test', method_name: "foo")

          expect(subject.stored[0].method_name).to eq("foo")
        end


        it "automatically sets the timestamp" do
          Timecop.freeze do
            Foo.new.bar

            bc = subject.stored[0]
            expect(bc.timestamp).to eq(Time.now.utc.to_i)
          end
        end

        it "does not set the timestamp if it is already set" do
          time = Time.now.utc

          Timecop.freeze do
            subject.record(message: 'test', timestamp: time)

            expect(subject.stored[0].timestamp).to_not eq(Time.now.utc)
          end
        end

        it "sets the log level to :info if one is not supplied" do
          Foo.new.bar

          expect(subject.stored[0].level).to eq(:info)
        end

        it "does not record the breadcrumb if should_record? is false" do
          expect(subject).to receive(:should_record?).and_return(false)
          Foo.new.bar

          expect(subject.stored.length).to eq(0)
        end
      end
    end
  end
end
