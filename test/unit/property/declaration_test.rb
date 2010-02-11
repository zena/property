require 'test_helper'
require 'fixtures'

class DeclarationTest < Test::Unit::TestCase

  context 'A sub-class' do
    context 'from a class with property columns' do
      setup do
        @klass = Developer
      end

      should 'inherit property columsn from parent class' do
        assert_equal %w{age first_name language last_name}, @klass.property_column_names.sort
      end

      should 'not back-propagate definitions to parent' do
        assert !@klass.superclass.property_columns.include?('language')
      end

      should 'inherit current definitions from parent' do
        class ParentClass < ActiveRecord::Base
          include Property
          property.string 'name'
        end
        @klass = Class.new(ParentClass) do
          property.integer 'age'
        end
        assert_equal %w{age name}, @klass.property_column_names.sort

        ParentClass.class_eval do
          property.string 'first_name'
        end

        assert_equal %w{age first_name name}, @klass.property_column_names.sort
      end

      should 'not be allowed to overwrite a property from the parent class' do
        assert_raise(TypeError) do
          @klass.class_eval do
            property.string 'age'
          end
        end
      end

      should 'not be allowed to overwrite a property from the current class' do
        assert_raise(TypeError) do
          @klass.class_eval do
            property.string 'language'
          end
        end
      end
    end
  end

  context 'Property declaration' do
    Superhero = Class.new(ActiveRecord::Base) do
      set_table_name :dummies
      include Property
    end

    subject { Class.new(Superhero) }

    should 'create Property::Column definitions' do
      subject.property.string('weapon')
      assert_kind_of Property::Column, subject.property_columns['weapon']
    end

    should 'create ruby accessors' do
      subject.property.string('weapon')
      assert subject.instance_methods.include?('weapon')
      assert subject.instance_methods.include?('weapon=')
      assert subject.instance_methods.include?('weapon?')
    end

    should 'not create accessors for illegal ruby names' do
      bad_names = ['some.thing', 'puts("yo")', '/var/', 'hello darness']
      assert_nothing_raised { subject.property.string bad_names }
      bad_names.each do |bad_name|
        assert !subject.instance_methods.include?(bad_name)
        assert !subject.instance_methods.include?("#{bad_name}=")
        assert !subject.instance_methods.include?("#{bad_name}?")
      end
    end

    should 'allow string columns' do
      subject.property.string('weapon')
      column = subject.property_columns['weapon']
      assert_equal 'weapon', column.name
      assert_equal String, column.klass
      assert_equal :string, column.type
    end

    should 'treat symbol keys as strings' do
      subject.property.string(:weapon)
      column = subject.property_columns['weapon']
      assert_equal 'weapon', column.name
      assert_equal String, column.klass
      assert_equal :string, column.type
    end

    should 'allow integer columns' do
      subject.property.integer('indestructible')
      column = subject.property_columns['indestructible']
      assert_equal 'indestructible', column.name
      assert_equal Fixnum, column.klass
      assert_equal :integer, column.type
    end

    should 'allow float columns' do
      subject.property.float('boat')
      column = subject.property_columns['boat']
      assert_equal 'boat', column.name
      assert_equal Float, column.klass
      assert_equal :float, column.type
    end

    should 'allow datetime columns' do
      subject.property.datetime('time_weapon')
      column = subject.property_columns['time_weapon']
      assert_equal 'time_weapon', column.name
      assert_equal Time, column.klass
      assert_equal :datetime, column.type
    end

    should 'allow default value option' do
      subject.property.integer('force', :default => 10)
      column = subject.property_columns['force']
      assert_equal 10, column.default
    end

    should 'allow indexed option' do
      subject.property.string('rolodex', :indexed => true)
      column = subject.property_columns['rolodex']
      assert column.indexed?
    end

    context 'in an instance singleton' do
      setup do
        @instance = subject.new
        @instance.property do |p|
          p.string 'instance_only'
        end
      end

      should 'behave like any other property column' do
        @instance.attributes = {'instance_only' => 'hello'}
        assert @instance.save
        @instance = subject.find(@instance.id)
        assert_equal Hash['instance_only' => 'hello'], @instance.prop
      end

      should 'not affect instance class' do
        assert !subject.property_column_names.include?('instance_only')
      end
    end
  end

  context 'Property columns' do
    Dummy = Class.new(ActiveRecord::Base) do
      set_table_name 'dummies'
      include Property
    end

    should 'return empty Hash if no property columsn are declared' do
      assert_equal Hash[], Dummy.property_columns
    end

    should 'return list of property columns from class' do
      assert_kind_of Hash, Employee.property_columns
      assert_kind_of Property::Column, Employee.property_columns['first_name']
    end
  end
end