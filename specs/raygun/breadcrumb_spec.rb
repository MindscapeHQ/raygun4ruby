require_relative "../spec_helper"

module Raygun
  describe Breadcrumb do
    let(:subject) { Breadcrumb.new }
    context 'fields' do
      it 'has a message' do
        message = 'foo'

        subject.message = message;

        subject.message.must_equal(message)
      end

      it 'has a category' do
        category = 'foo'

        subject.category = category;

        subject.category.must_equal(category)
      end

      it 'has a level' do
        message = 'foo'

        subject.message = message;

        subject.message.must_equal(message)
      end

      it 'has metadata' do
        metadata = {foo: '1'}

        subject.metadata = metadata;

        subject.metadata.must_equal(metadata)
      end

      it 'has a class_name' do
        class_name = 'foo'

        subject.class_name = class_name;

        subject.class_name.must_equal(class_name)
      end

      it 'has a method_name' do
        method_name = 'foo'

        subject.method_name = method_name;

        subject.method_name.must_equal(method_name)
      end

      it 'has a line_number' do
        line_number = 17

        subject.line_number = line_number;

        subject.line_number.must_equal(line_number)
      end
    end
  end
end
