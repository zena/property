require 'test_helper'
require 'fixtures'

class RoleTest < Test::Unit::TestCase
  should_store_property_definitions(Property::Role)


  context 'A Poet role' do
    setup do
      @poet = Property::Role.new('Poet') do |p|
        p.string 'poem', :default => :muse

        p.actions do
          def muse
            'I am your muse'
          end
        end
      end
    end

    should_insert_properties_on_has_role_poet
    should_add_role_methods
    should_take_part_in_used_list

    should 'return name on name' do
      assert_equal 'Poet', @poet.name
    end
  end # A Poet role

  context 'A class used as role' do
    class Foo < ActiveRecord::Base
      include Property

      property do |p|
        p.string 'poem', :default => :muse

        p.actions do
          def muse
            'I am your muse'
          end
        end
      end
    end

    setup do
      @poet = Foo
    end

    should_insert_properties_on_has_role_poet
    should_add_role_methods
    should_take_part_in_used_list

    context 'set on a sub-class instance' do
      subject do
        Employee.new
      end

      should 'not raise an exception' do
        assert_nothing_raised { subject.has_role Developer }
      end
    end # set on a sub-class instance
  end # A class used as role
end