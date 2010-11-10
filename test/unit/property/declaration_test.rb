require 'test_helper'
require 'fixtures'

class DeclarationTest < Test::Unit::TestCase

  context 'A sub-class' do
    context 'from a class with property columns' do
      setup do
        @ParentClass = Class.new(ActiveRecord::Base) do
          include Property
          property.string 'name'
          def method_in_parent
          end
        end
      end

      subject do
        Class.new(@ParentClass) do
          property.integer 'age'
          def method_in_self
          end
        end
      end

      should 'inherit property columns from parent class' do
        assert_equal %w{age name}, subject.schema.column_names.sort
      end

      should 'see its property columns in schema' do
        assert subject.schema.has_column?('age')
      end

      should 'not back-propagate definitions to parent' do
        assert !subject.superclass.schema.has_column?('age')
      end

      should 'inherit new definitions in parent' do
        @ParentClass.class_eval do
          property.string 'first_name'
        end

        assert_equal %w{age first_name name}, subject.schema.column_names.sort
      end

      # This is allowed: it's the user's responsability to make sure such a thing does not happen
      # or cause problems.
      should 'be allowed to overwrite a property from the parent class' do
        assert_nothing_raised do
          subject.class_eval do
            property.string 'name'
          end
        end
      end

      should 'not be allowed to overwrite a property from the current class' do
        assert_raise(Property::RedefinedPropertyError) do
          subject.class_eval do
            property.string 'age'
          end
        end
      end

      # This is allowed, it's the user's responsability to make sure such a thing does not cause
      # problems.
      should 'be allowed to define a property with the name of a method in the parent class' do
        assert_nothing_raised do
          subject.class_eval do
            property.string 'method_in_parent'
          end
        end
      end

      # This is ok because it can be useful and the module inclusion would not hide it
      should 'be allowed to define a property with the same name as a method in the current class' do
        assert_nothing_raised do
          subject.class_eval do
            property.string 'method_in_self'
          end
        end
      end
    end
  end

  context 'An instance' do
    subject do
      Class.new(ActiveRecord::Base) do
        set_table_name :dummies
        include Property
      end.new
    end

    should 'be able to include a role with _name_ property' do
      role_with_name = Property::Role.new('foo')
      role_with_name.property do |p|
        p.string :name
      end

      assert_nothing_raised do
        subject.include_role role_with_name
      end
    end
  end # An instance

  context 'Property declaration' do
    Superhero = Class.new(ActiveRecord::Base) do
      set_table_name :dummies
      include Property
    end

    subject { Class.new(Superhero) }

    should 'create Property::Column definitions' do
      subject.property.string('weapon')
      assert_kind_of Property::Column, subject.schema.columns['weapon']
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
      column = subject.schema.columns['weapon']
      assert_equal 'weapon', column.name
      assert_equal String, column.klass
      assert_equal :string, column.type
    end

    should 'allow text columns' do
      subject.property.text('history')
      column = subject.schema.columns['history']
      assert_equal 'history', column.name
      assert_equal String, column.klass
      assert_equal :text, column.type
    end

    should 'treat symbol keys as strings' do
      subject.property.string(:weapon)
      column = subject.schema.columns['weapon']
      assert_equal 'weapon', column.name
      assert_equal String, column.klass
      assert_equal :string, column.type
    end

    should 'allow integer columns' do
      subject.property.integer('indestructible')
      column = subject.schema.columns['indestructible']
      assert_equal 'indestructible', column.name
      assert_equal Fixnum, column.klass
      assert_equal :integer, column.type
    end

    should 'allow float columns' do
      subject.property.float('boat')
      column = subject.schema.columns['boat']
      assert_equal 'boat', column.name
      assert_equal Float, column.klass
      assert_equal :float, column.type
    end

    should 'allow datetime columns' do
      subject.property.datetime('time_weapon')
      column = subject.schema.columns['time_weapon']
      assert_equal 'time_weapon', column.name
      assert_equal Time, column.klass
      assert_equal :datetime, column.type
    end

    should 'allow multiple declarations in one go' do
      subject.property.string 'foo', 'bar', 'baz'
      assert_equal %w{bar baz foo}, subject.schema.column_names.sort
    end

    should 'allow multiple declarations in an Array' do
      subject.property.string ['foo', 'bar', 'baz']
      assert_equal %w{bar baz foo}, subject.schema.column_names.sort
    end

    should 'allow serialized columns' do
      Cat = Struct.new(:name, :toy) do
        def self.json_create(data)
          Cat.new(data['name'], data['toy'])
        end
        def to_json(*args)
          { 'json_class' => self.class.to_s,
            'name' => @name, 'toy' => @toy
          }.to_json(*args)
        end
      end

      subject.property.serialize('pet', Cat)
      column = subject.schema.columns['pet']
      assert_equal 'pet', column.name
      assert_equal Cat, column.klass
      assert_equal nil, column.type
    end

    should 'allow default value option' do
      subject.property.integer('force', :default => 10)
      column = subject.schema.columns['force']
      assert_equal 10, column.default
    end

    should 'allow index option' do
      subject.property.string('rolodex', :index => true)
      column = subject.schema.columns['rolodex']
      assert column.indexed?
    end

    context 'through a Role on an instance' do
      setup do
        @instance = subject.new
        @poet = Property::Role.new('Poet')
        @poet.property do |p|
          p.string 'poem'
        end

        @instance.include_role @poet
      end

      should 'behave like any other property column' do
        @instance.attributes = {'poem' => 'hello'}
        @instance.poem = 'shazam'
        assert @instance.save
        @instance = subject.find(@instance.id)
        assert_equal Hash['poem' => 'shazam'], @instance.prop
      end

      should 'use method_missing for property methods' do
        assert !@instance.respond_to?(:poem=)
        assert_nothing_raised do
          @instance.poem = 'shazam'
          assert_equal 'shazam', @instance.poem
        end
      end

      should 'not affect instance class' do
        assert !subject.schema.column_names.include?('poem')
        assert_raise(NoMethodError) do
          instance = subject.new
          instance.poem = 'not a poet'
        end
      end
    end
  end

  context 'Property columns' do
    Dummy = Class.new(ActiveRecord::Base) do
      set_table_name 'dummies'
      include Property
    end

    should 'return empty Hash if no property columsn are declared' do
      assert_equal Hash[], Dummy.schema.columns
    end

    should 'return list of property columns from class' do
      assert_kind_of Hash, Employee.schema.columns
      assert_kind_of Property::Column, Employee.schema.columns['first_name']
    end
  end

  context 'A class with a schema' do
    subject { Class.new(Developer) }

    should 'raise an exception if we ask to behave like a class without schema' do
      assert_raise(TypeError) { subject.include_role String }
    end

    should 'raise an exception if we ask to behave like an object' do
      assert_raise(TypeError) { subject.include_role 'me' }
    end

    should 'inherit properties when asking to behave like a class' do
      @class = Class.new(ActiveRecord::Base) do
        include Property
        property do |p|
          p.string 'hop'
        end
      end

      subject.include_role @class
      assert_equal %w{language last_name hop age first_name}, subject.schema.column_names
      assert subject.has_role?(@class.schema)
    end
  end

  context 'A class with external storage' do
    class Version < ActiveRecord::Base
      belongs_to :contact, :class_name => 'DeclarationTest::Contact',
                 :foreign_key => 'employee_id'
    end

    class Contact < ActiveRecord::Base
      attr_accessor :assertion
      before_save :before_save_assertion
      set_table_name :employees
      has_many :versions, :class_name => 'DeclarationTest::Version'

      include Property
      store_properties_in :version

      property do |p|
        p.string 'first_name'
        p.string 'famous', :default => :get_is_famous
        p.integer 'age'
      end

      def get_is_famous
        'no'
      end

      def version
        @version ||= begin
          if new_record?
            versions.build
          else
            Version.first(:conditions => ['employee_id = ?', self.id]) || versions.build
          end
        end
      end

      private
        def before_save_assertion
          return true unless @assertion
          @assertion.call
          true
        end
    end

    setup do
      @contact = Contact.create('first_name' => 'Martin')
    end

    subject { @contact }

    should 'store properties in the given instance' do
      assert_equal Hash["famous"=>"no", "first_name"=>"Martin"], JSON.parse(subject.version['properties'])
    end

    should 'keep a properties cache in the the main instance' do
      assert_equal Hash["famous"=>"no", "first_name"=>"Martin"], subject.instance_variable_get(:@properties)
    end

    should 'behave as if storage was internal' do
      subject.first_name = 'Hannah'
      assert_equal 'no', subject.famous
      assert_equal Hash["first_name"=>["Martin", "Hannah"]], subject.changes
    end

    should 'dump properties before any before_save triggers' do
      subject.assertion = Proc.new do
        assert_match %r{Karl}, subject.version.properties
      end
      subject.update_attributes('first_name' => 'Karl')
    end
  end
end
















