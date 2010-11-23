require 'test_helper'
require 'fixtures'

class ValidationTest < Test::Unit::TestCase

  context 'When setting a property' do
    Pirate = Class.new(ActiveRecord::Base) do
      set_table_name 'dummies'
      include Property
      property.float 'boat'
      property.string 'bird_name'
      property.serialize 'cat', Cat
    end

    subject { Pirate.create }

    context 'without a property column' do
      context 'set with attributes=' do
        should 'not raise an error' do
          subject.update_attributes('infamous' => 'dictator')
        end

        should 'set an error message' do
          subject.update_attributes('infamous' => 'dictator')
          assert_equal subject.errors['infamous'], 'property not declared'
        end
      end # set with attributes=

      should 'set an error message' do
        subject.prop['infamous'] = 'dictator'
        assert !subject.save
        assert_equal subject.errors['infamous'], 'property not declared'
      end

      context 'with dirty' do
        should 'validate if property was not changed' do
          subject.prop.instance_eval do
            self['infamous'] = 'dictator'
            @original_hash['infamous'] = 'dictator'
          end

          assert subject.update_attributes('boat' => 'Tiranic')

          # value should not be removed
          assert_equal 'dictator', subject.prop['infamous']
        end

        should 'validate if no property was changed' do
          subject.prop.instance_eval do
            self['infamous'] = 'dictator' # simulate legacy value
            @original_hash = nil
          end

          assert subject.valid?
        end
      end
    end

    context 'from the wrong data type' do
      setup do
        subject.update_attributes('boat' => Time.now, 'bird_name' => 1337)
      end

      should 'cast the data type' do
        assert subject.valid?
        assert_kind_of Float, subject.prop['boat']
        assert_kind_of String, subject.prop['bird_name']
        assert_equal '1337', subject.prop['bird_name']
      end

      should 'show an error for serialized types' do
        subject.update_attributes('cat' => 'Joann Sfar')
        assert !subject.valid?
        assert_equal 'cannot cast String to Cat', subject.errors['cat']
      end
    end

    context 'to a blank value' do
      subject { Pirate.create('bird_name' => 'Rainbow Lorikeet') }

      should 'accept nil' do
        assert subject.update_attributes('bird_name' => nil)
      end

      should 'accept empty string' do
        assert subject.update_attributes('bird_name' => '')
      end

      should 'clear property if there is no default' do
        subject.update_attributes('bird_name' => '')
        assert_nil subject.properties['bird_name']
      end
    end

  end # When setting a property

  context 'On a class with default property values' do
    class Cat < ActiveRecord::Base
      attr_accessor :encoding
      set_table_name 'dummies'

      include Property
      property do |p|
        p.string 'eat', :default => 'mouse'
        p.string 'name'
        p.datetime 'seen_at', :default => Proc.new { Time.now }
        p.string 'encoding', :default => :get_encoding
      end

      def get_encoding
        @encoding
      end
    end

    should 'insert default literal values' do
      subject = Cat.create
      subject.reload
      assert_equal 'mouse', subject.prop['eat']
    end

    should 'call procs to get default if missing' do
      subject = Cat.create
      assert_kind_of Time, subject.prop['seen_at']
    end

    should 'call procs to get default if empty' do
      subject = Cat.new('seen_at' => '')
      assert_kind_of Time, subject.prop['seen_at']
    end

    should 'call owner methods to get default' do
      subject = Cat.new
      subject.encoding = 'yooupla/boom'
      assert subject.save

      assert_equal 'yooupla/boom', subject.prop['encoding']
    end

    should 'accept other values' do
      subject = Cat.create('eat' => 'birds')
      subject.reload
      assert_equal 'birds', subject.prop['eat']
    end

    should 'revert to default value when set to empty string' do
      subject = Cat.create('eat' => 'birds')
      subject.update_attributes('eat' => '')
      assert_equal 'mouse', subject.prop['eat']
    end

    should 'revert to default value when set to nil' do
      subject = Cat.create('eat' => 'birds')
      subject.update_attributes('eat' => nil)
      assert_equal 'mouse', subject.prop['eat']
    end
  end
end