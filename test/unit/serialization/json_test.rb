# encoding: UTF-8
require "test_helper"
require 'property/serialization/json'

class MyJSON
  include Property::Serialization::JSON
end

class MyJSONTest < Test::Unit::TestCase

  should_encode_and_decode_properties

  context 'JSON validator' do
    subject { Property::Serialization::JSON::Validator }

    should 'respond to validate' do
      assert subject.respond_to? :validate
    end

    [Property::Properties, String, Integer, Float].each do |a_class|
      should "accept to serialize #{a_class}" do
        assert subject.validate(a_class)
      end
    end
  end

  context 'on a class with properties as custom type' do
    subject do
      Class.new(ActiveRecord::Base) do
        include Property
      end
    end

    should 'raise an exception if we try to encode an invalid class' do
      assert_raise(TypeError) { subject.property.serialize 'not_json', Regexp }
    end
  end
end