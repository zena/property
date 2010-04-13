class Test::Unit::TestCase
  def self.should_store_property_definitions(klass)

    context 'A Behavior' do
      subject { klass.new('Foobar') }

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

      should 'allow index option' do
        subject.property.string('rolodex', :index => true)
        column = subject.columns['rolodex']
        assert column.indexed?
      end

      should 'return a list of indices on indices' do
        subject.property.string('rolodex', :index => true)
        subject.property.integer('foobar', :index => true)
        assert_equal %w{integer string}, subject.indices.map {|i| i[0].to_s }.sort
      end

      context 'created with a Hash' do
        subject { klass.new(:name => 'Foobar') }

        should 'set name' do
          assert_equal 'Foobar', subject.name
        end
      end

      context 'created with a String Hash' do
        subject { klass.new('name' => 'Foobar') }

        should 'set name' do
          assert_equal 'Foobar', subject.name
        end
      end
    end # A Behavior
  end # should_store_property_definitions

  def self.should_insert_properties_on_behave_like_poet
    context 'Adding a behavior' do

      context 'to a class' do
        setup do
          @parent = Class.new(ActiveRecord::Base) do
            set_table_name :dummies
            include Property
            property.string 'name'
          end

          @klass = Class.new(@parent)
        end

        should 'propagate definitions to child' do
          @parent.behave_like @poet
          assert_equal %w{name poem}, @klass.schema.column_names.sort
        end

        should 'raise an exception if class contains same definitions' do
          @parent.property.string 'poem'
          assert_raise(Property::RedefinedPropertyError) { @parent.behave_like @poet }
        end

        should 'not raise an exception on double inclusion' do
          @parent.behave_like @poet
          assert_nothing_raised { @parent.behave_like @poet }
        end

        should 'add accessor methods to child' do
          subject = @klass.new
          assert_raises(NoMethodError) { subject.poem = 'Poe'}
          @parent.behave_like @poet

          assert_nothing_raised { subject.poem = 'Poe'}
        end
      end

      context 'to a parent class' do
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
  end # should_insert_properties_on_behave_like

  def self.should_add_behavior_methods
    context 'Adding a behavior with methods' do

      context 'to a class' do
        setup do
          @parent = Class.new(ActiveRecord::Base) do
            set_table_name :dummies
            include Property
            property.string 'name'
          end

          @klass = Class.new(@parent)
        end

        should 'add behavior methods to child' do
          subject = @klass.new
          assert_raises(NoMethodError) { subject.muse }
          @parent.behave_like @poet

          assert_nothing_raised { subject.muse }
        end

        should 'use behavior methods for defaults' do
          subject = @klass.new
          @parent.behave_like @poet
          assert subject.save
          assert_equal 'I am your muse', subject.poem
        end
      end
    end
  end # should_add_behavior_methods
end