require 'test_helper'
require 'fixtures'

class StoredRoleTest < ActiveSupport::TestCase
  class Column < ActiveRecord::Base
    include Property::StoredColumn
  end

  class Role < ActiveRecord::Base
    include Property::StoredRole
    has_many :stored_columns, :class_name => 'StoredRoleTest::Column'
  end

  should_store_property_definitions(Role)

  context 'A stored Role' do

    context 'with column definitions' do
      setup do
        role = Role.create(:name => 'Poet')
        role.stored_columns << Column.new(:ptype => 'string',  :name => 'poem')
        role.save!
        @poet = Role.find(role.id)
      end

      should_insert_properties_on_has_role_poet
      should_take_part_in_used_list(false)

      should 'create new role columns on save' do
        @poet.property do |p|
          p.integer 'year'
        end

        assert_difference('Role.count', 0) do
          assert_difference('Column.count', 1) do
            @poet.save
          end
        end
      end
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
