require 'test_helper'
require 'fixtures'

class IndexSimpleTest < ActiveSupport::TestCase

  # Simple index definition class
  class Dog < ActiveRecord::Base
    include Property
    set_table_name :employees

    def save_with_raise
      if name == 'raise'
        raise Exception.new
      else
        save_without_raise
      end
    end
    alias_method_chain :save, :raise

    property do |p|
      p.string  'name', :index   => :special
      p.integer 'age',  :indexed => true # synonym
    end
  end

  context 'A schema from a class with index definitions' do
    subject do
      Dog.schema
    end

    should 'return a Hash on index_groups' do
      assert_kind_of Hash, subject.index_groups
    end

    should 'group indices by type' do
      assert_equal %w{integer special}, subject.index_groups.keys.map(&:to_s).sort
    end
    
    should 'not contain duplicates' do
      assert_equal Hash["special"=>[["name", nil]], "integer"=>[["age", nil]]], subject.index_groups
    end
  end

  context 'A class with a simple index definition' do
    subject do
      Dog
    end

    class Mongrel < Dog
      attr_accessor :last_index_group_name
      def create_indices(group_name, new_keys, cur_indices)
        @last_index_group_name = group_name
        super
      end
    end

    context 'on record creation' do
      should 'create index entries' do
        assert_difference('IdxEmployeesSpecial.count', 1) do
          Dog.create('name' => 'Pavlov')
        end
      end

      should 'call create_indices to create index entries' do
         m = Mongrel.create('name' => 'Zed')
         assert_equal 'special', m.last_index_group_name
       end

      should 'not create index entries for blank values' do
        assert_difference('IdxEmployeesInteger.count', 0) do
          Dog.create('name' => 'Pavlov')
        end
      end

      should 'special indices linked to the model' do
        dog = Dog.create('name' => 'Pavlov')
        index_string = IdxEmployeesSpecial.first(:conditions => {:employee_id => dog.id})
        assert_equal 'Pavlov', index_string.value
        assert_equal 'name', index_string.key
      end

      should 'store a key and value pair linked to the model' do
        dog = Dog.create('age' => 15)
        index_integer = IdxEmployeesInteger.first(:conditions => {:employee_id => dog.id})
        assert_equal 15, index_integer.value
        assert_equal 'age', index_integer.key
      end
    end

    context 'on record update' do
      setup do
        @dog = Dog.create('name' => 'Pavlov')
      end

      should 'update index entries' do
        index_string = IdxEmployeesSpecial.first(:conditions => {:employee_id => @dog.id})
        assert_difference('IdxEmployeesSpecial.count', 0) do
          @dog.update_attributes('name' => 'Médor')
        end

        index_string = IdxEmployeesSpecial.find(index_string.id)
        assert_equal 'Médor', index_string.value
        assert_equal 'name', index_string.key
      end

      should 'not create index entries for blank values' do
        assert_difference('IdxEmployeesInteger.count', 0) do
          @dog.update_attributes('name' => 'Médor')
        end
      end

      should 'remove blank values' do
        assert_difference('IdxEmployeesSpecial.count', -1) do
          @dog.update_attributes('name' => '')
        end
      end

      should 'create new entries for new keys' do
        assert_difference('IdxEmployeesInteger.count', 1) do
          @dog.update_attributes('age' => 7)
        end
      end

      should 'store a key and value pair linked to the model' do
        @dog.update_attributes('age' => 7)
        index_int = IdxEmployeesInteger.first(:conditions => {:employee_id => @dog.id})
        assert_equal 7, index_int.value
        assert_equal 'age', index_int.key
      end

      context 'that fails during save' do
        setup do
          @dog = Dog.create('name' => 'Pavlov')
        end

        should 'not alter indices' do
          assert_difference('IdxEmployeesInteger.count', 0) do
            assert_raises(Exception) do
              @dog.update_attributes('name' => 'raise')
            end
          end

          index_string = IdxEmployeesSpecial.first(:conditions => {:employee_id => @dog.id})
          assert_equal 'Pavlov', index_string.value
          assert_equal 'name', index_string.key
        end

      end
    end

    context 'on record destruction' do
      should 'remove index entries' do
        dog = Dog.create('name' => 'Pavlov', 'age' => 7)
        assert_difference('IdxEmployeesSpecial.count', -1) do
          assert_difference('IdxEmployeesInteger.count', -1) do
            dog.destroy
          end
        end
      end
    end
  end
end