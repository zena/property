require 'test_helper'
require 'fixtures'

class RoleTest < ActiveSupport::TestCase
  should_store_property_definitions(Property::Role)


  context 'A Poet role' do
    setup do
      @poet = Property::Role.new('Poet') do |p|
        p.string 'poem', :default => :muse
        p.integer 'year'
      end
    end

    should_insert_properties_on_include_role_poet
    should_take_part_in_used_list
    should_not_maintain_indices # no indexed column defined

    should 'return name on name' do
      assert_equal 'Poet', @poet.name
    end
  end # A Poet role

  context 'A Poet role with indices' do
    setup do
      @poet = Property::Role.new('Poet') do |p|
        p.string  'poem', :index => :ml_string
        p.integer 'year', :index => true
      end
    end

    should_maintain_indices
  end # A Poet role with indices


  context 'A class used as role' do
    class Foo < ActiveRecord::Base
      include Property

      property do |p|
        p.string 'poem', :default => :muse
        p.integer 'year'
      end

      def muse
        'I am your muse'
      end
    end

    setup do
      @poet = Foo
    end

    should_insert_properties_on_include_role_poet
    should_take_part_in_used_list

    context 'set on a sub-class instance' do
      subject do
        Employee.new
      end

      should 'not raise an exception' do
        assert_nothing_raised { subject.include_role Developer }
      end
    end # set on a sub-class instance
  end # A class used as role
end