require 'test_helper'
require 'fixtures'

class BehaviorTest < Test::Unit::TestCase

  context 'A Behavior' do
    subject { Property::Behavior.new('Foobar') }

    should 'allow string columns' do
      subject.property.string('weapon')
      column = subject.columns['weapon']
      assert_equal 'weapon', column.name
      assert_equal String, column.klass
      assert_equal :string, column.type
    end

    should 'treat symbol keys as strings' do
      subject.property.string(:weapon)
      column = subject.columns['weapon']
      assert_equal 'weapon', column.name
      assert_equal String, column.klass
      assert_equal :string, column.type
    end

    should 'allow integer columns' do
      subject.property.integer('indestructible')
      column = subject.columns['indestructible']
      assert_equal 'indestructible', column.name
      assert_equal Fixnum, column.klass
      assert_equal :integer, column.type
    end

    should 'allow float columns' do
      subject.property.float('boat')
      column = subject.columns['boat']
      assert_equal 'boat', column.name
      assert_equal Float, column.klass
      assert_equal :float, column.type
    end

    should 'allow datetime columns' do
      subject.property.datetime('time_weapon')
      column = subject.columns['time_weapon']
      assert_equal 'time_weapon', column.name
      assert_equal Time, column.klass
      assert_equal :datetime, column.type
    end

    should 'allow default value option' do
      subject.property.integer('force', :default => 10)
      column = subject.columns['force']
      assert_equal 10, column.default
    end

    should 'allow indexed option' do
      subject.property.string('rolodex', :indexed => true)
      column = subject.columns['rolodex']
      assert column.indexed?
    end
  end # A Behavior

  context 'Adding a behavior' do
    setup do
      @poet = Property::Behavior.new('Poet') do |p|
        p.string 'poem'
      end
    end

    context 'to a class' do
    end

    context 'to an instance' do
      subject { Developer.new }

      setup do
        subject.behave_like @poet
      end

      should 'merge property definitions' do
        assert_equal %w{age first_name language last_name poem}, subject.schema.column_names.sort
      end
    end
  end
end