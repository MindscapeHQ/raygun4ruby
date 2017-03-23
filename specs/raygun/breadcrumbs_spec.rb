require "minitest/autorun"
require "minitest/pride"
require_relative "../spec_helper"

module Raygun
  describe Breadcrumbs do
    context "store" do
      describe "#initialize_store" do
        before do
          Breadcrumbs.stored.must_equal(nil)

          Breadcrumbs.initialize_store
        end

        after do
          Breadcrumbs.clear_store
        end

        it "creates the store on the current Thread" do
          Breadcrumbs.stored.must_equal([])
        end

        it "does not effect other threads" do
          Thread.new do
            Breadcrumbs.stored.must_equal(nil)
          end.join
        end
      end

      describe "#clear_store" do
        before do
          Breadcrumbs.initialize_store
        end

        it "resets the store back to nil" do
          Breadcrumbs.clear_store

          Breadcrumbs.stored.must_equal(nil)
        end
      end
    end
  end
end
