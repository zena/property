require 'test_helper'
require 'fixtures'

class StoredRoleTest < ActiveSupport::TestCase
  StoredRole = Property::StoredRole
  StoredColumn = Property::StoredColumn

  should_store_property_definitions(StoredRole)

  context 'A stored StoredRole' do

    context 'with column definitions' do
      setup do
        role = StoredRole.create(:name => 'Poet')
        role.stored_columns << StoredColumn.new(:ptype => 'string',  :name => 'poem')
        role.save!
        @poet = StoredRole.find(role.id)
      end

      should_insert_properties_on_has_role_poet
      should_take_part_in_used_list(false)

      should 'create new role columns on save' do
        @poet.property do |p|
          p.integer 'year'
        end

        assert_difference('StoredRole.count', 0) do
          assert_difference('StoredColumn.count', 1) do
            @poet.save
          end
        end
      end
    end # with column definitions
  end # A stored StoredRole

  context 'A new StoredRole' do
    subject do
      StoredRole.new('Poet') do |p|
        p.string 'name'
      end
    end

    should 'define properties with a block' do
      assert_equal %w{name}, subject.column_names
    end

    should 'create role columns on save' do
      role = subject
      assert_difference('StoredRole.count', 1) do
        assert_difference('StoredColumn.count', 1) do
          role.save
        end
      end
    end
  end # A new StoredRole
end
