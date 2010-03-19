require 'test_helper'
require 'fixtures'

class IndexTest < ActiveSupport::TestCase
  class IndexedStringEmp < ActiveRecord::Base
    set_table_name :i_string_employees
  end
  
  class IndexedIntegerEmp < ActiveRecord::Base
    set_table_name :i_integer_employees
  end

  # Simple index definition class
  class Dog < ActiveRecord::Base
    include Property
    set_table_name :employees

    property do |p|
      p.string  'name', :index   => true
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

    should 'group indexes by type' do
      assert_equal %w{integer string}, subject.index_groups.keys.map(&:to_s).sort
    end
  end

  context 'A class with a simple index definition' do
    subject do
      Dog
    end

    context 'on record creation' do
      should 'create index entries' do
        assert_difference('IndexedStringEmp.count', 1) do
          Dog.create('name' => 'Pavlov')
        end
      end
      
      should 'not create index entries for blank values' do
        assert_difference('IndexedIntegerEmp.count', 0) do
          Dog.create('name' => 'Pavlov')
        end
      end

      should 'store a key and value pair linked to the model' do
        dog = Dog.create('name' => 'Pavlov')
        index_string = IndexedStringEmp.first(:conditions => {:employee_id => dog.id})
        assert_equal 'Pavlov', index_string.value
        assert_equal 'name', index_string.key
      end
    end

    context 'on record destruction' do
      should 'remove index entries' do
        dog = Dog.create('name' => 'Pavlov')
        assert_difference('IndexedStringEmp.count', -1) do
          dog.destroy
        end
      end
    end
  end
end