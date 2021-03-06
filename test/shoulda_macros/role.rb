class Test::Unit::TestCase
  def self.should_store_property_definitions(klass)
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

    should 'return a list of indices on defined_indices' do
      subject.property.string('rolodex', :index => true)
      subject.property.integer('foobar', :index => true)
      assert_equal %w{integer string}, subject.defined_indices.map {|i| i[0].to_s }.sort
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
  end # should_store_property_definitions

  def self.should_insert_properties_on_include_role_poet
    context 'added' do

      context 'to a parent class' do
        setup do
          @parent = Class.new(ActiveRecord::Base) do
            set_table_name :dummies
            include Property
            property.string 'name'

            def muse
              'I am your muse'
            end
          end

          @klass = Class.new(@parent)
        end

        should 'propagate definitions to child' do
          @parent.include_role @poet
          assert_equal %w{name poem year}, @klass.schema.column_names.sort
        end

        should 'return true on has_role?' do
          @parent.include_role @poet
          assert @klass.has_role?(@poet)
        end

        should 'not raise an exception on double inclusion' do
          @parent.include_role @poet
          assert_nothing_raised { @parent.include_role @poet }
        end

        should 'add accessor methods to child' do
          subject = @klass.new
          assert_raises(NoMethodError) { subject.poem = 'Poe'}
          @parent.include_role @poet

          assert_nothing_raised { subject.poem = 'Poe'}
        end
      end

      context 'to a class' do
        setup do
          @klass = Class.new(ActiveRecord::Base) do
            set_table_name :dummies
            include Property
            property.string 'name'

            def muse
              'I am your muse'
            end
          end
        end

        should 'insert definitions' do
          @klass.include_role @poet
          assert_equal %w{name poem year}, @klass.schema.column_names.sort
        end

        should 'return true on class has_role?' do
          @klass.include_role @poet
          assert @klass.has_role?(@poet)
        end

        should 'return role from column' do
          @klass.include_role @poet
          assert_equal (@poet.kind_of?(Class) ? @poet.schema : @poet), @klass.schema.columns['poem'].role
        end
      end

      context 'to an instance' do
        subject { Developer.new }

        setup do
          subject.include_role @poet
        end

        should 'merge property definitions' do
          assert_equal %w{age first_name language last_name poem year}, subject.schema.column_names.sort
        end
      end
    end
  end # should_insert_properties_on_include_role_poet

  def self.should_take_part_in_used_list(has_defaults = true)

    context 'added' do
      context 'to a class' do
        setup do
          @klass = Class.new(ActiveRecord::Base) do
            set_table_name :dummies
            include Property
            property.string 'name'

            def muse
              'I am your muse'
            end
          end

          @klass.include_role @poet
        end

        subject do
          @klass.new
        end

        should 'return true on instance has_role?' do
          assert subject.has_role?(@poet)
        end

        should 'not return role without corresponding attributes' do
          subject.attributes = {'name' => 'hello'}
          assert_equal [@klass.schema], subject.used_roles
        end

        should 'return role with corresponding attributes' do
          subject.attributes = {'poem' => 'hello'}
          roles = @poet.kind_of?(Class) ? @poet.schema.roles : [@poet]
          assert_equal roles, subject.used_roles
        end

        should 'not return role only with blank attributes' do
          subject.attributes = {'name' => ''}
          assert_equal [], subject.used_roles
        end

        if has_defaults
          should 'return role with default attributes after validate' do
            subject.valid?
            roles = @poet.kind_of?(Class) ? @poet.schema.roles : [@poet]
            assert_equal roles, subject.used_roles
          end
        end
      end # to a class
    end # added
  end
end