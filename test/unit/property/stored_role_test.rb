require 'test_helper'
require 'fixtures'

class StoredRoleTest < ActiveSupport::TestCase
  class Column < ActiveRecord::Base
    include Property::StoredColumn
  end

  class Role < ActiveRecord::Base
    include Property::StoredRole
    stored_columns_class 'StoredRoleTest::Column'
  end

  should_store_property_definitions(Role)

  context 'A stored Role' do

    context 'with column definitions' do
      setup do
        role = Role.create(:name => 'Poet')
        role.stored_columns << Column.new(:ptype => 'string',  :name => 'poem')
        role.stored_columns << Column.new(:ptype => 'integer', :name => 'year')
        role.save!
        @poet = Role.find(role.id)
      end

      
      # ========================== should_insert_properties_on_include_role_poet
      
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
      # ==========================
      should_take_part_in_used_list(false)
      should_not_maintain_indices # no indexed column defined

      should 'create new role columns on save' do
        @poet.property do |p|
          p.string 'original_language'
        end

        assert_difference('Role.count', 0) do
          assert_difference('Column.count', 1) do
            @poet.save
          end
        end
      end

      should 'return name on name' do
        assert_equal 'Poet', @poet.name
      end
    end # with column definitions
  end # A stored Role

  context 'A stored Role' do

    context 'with indexed column definitions' do
      setup do
        role = Role.create(:name => 'Poet')
        role.stored_columns << Column.new(:ptype => 'string',  :name => 'poem', :index => :ml_string)
        role.stored_columns << Column.new(:ptype => 'integer', :name => 'year', :index => true)
        role.save!
        @poet = Role.find(role.id)
      end

      should_maintain_indices
    end # with column definitions
  end # A stored Role

  context 'A new Role' do
    subject do
      Role.new('Poet') do |p|
        p.string 'name'
      end
    end

    should 'define properties with a block' do
      assert_equal %w{name}, subject.column_names
    end

    should 'create role columns on save' do
      role = subject
      assert_difference('Role.count', 1) do
        assert_difference('Column.count', 1) do
          assert role.save
        end
      end
    end
  end # A new Role
end
