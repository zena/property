require 'test_helper'
require 'fixtures'

class IndexComplexTest < ActiveSupport::TestCase
  # Complex index definition class
  class Person < ActiveRecord::Base
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
      p.string  'name'
      # only runs if 'age' is not blank
      p.integer 'age', :index => Proc.new {|r| {'age' => r.age == 0 ? nil : r.age + 10}}
      p.string  'gender'
      p.string  'lang'

      p.index(:text) do |r| # r = record
        {
          "high"           => "gender:#{r.gender} age:#{r.age} name:#{r.name}",
          "name_#{r.lang}" => r.name, # multi-lingual index only matching existing object in required lang
        }
      end
    end
  end

  context 'A schema from a class with complex index definitions' do
    subject do
      Person.schema
    end

    should 'return a Hash on index_groups' do
      assert_kind_of Hash, subject.index_groups
    end

    should 'group indices by type' do
      assert_equal %w{integer text}, subject.index_groups.keys.map(&:to_s).sort
    end
  end

  context 'A class with complex index definition' do
    subject do
      Person
    end

    context 'on record creation' do
      should 'create index entries' do
        assert_difference('IdxEmployeesText.count', 2) do
          Person.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
        end
      end

      should 'not create index entries for blank values' do
        assert_difference('IdxEmployeesInteger.count', 0) do
          Person.create('name' => 'Pavlov')
        end
      end

      should 'store key and value pairs linked to the model' do
        person = Person.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
        high_index, name_index = IdxEmployeesText.all(:conditions => {:employee_id => person.id}, :order => 'key asc')
        assert_equal 'high', high_index.key
        assert_equal 'gender:M age:34 name:Juan', high_index.value
        assert_equal 'name_es', name_index.key
        assert_equal 'Juan', name_index.value
      end

      should 'execute index Proc to build value' do
        person = Person.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
        int_index = IdxEmployeesInteger.first(:conditions => {:employee_id => person.id})
        assert_equal 44, int_index.value
      end

      should 'remove blank values built from proc execution' do
        person = Person.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
        assert_difference('IdxEmployeesInteger.count', -1) do
          person.update_attributes('age' => 0)
        end
      end
    end

    context 'on record update' do
      setup do
        @person = Person.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
      end

      should 'update index entries' do
        high_index, name_index = IdxEmployeesText.all(:conditions => {:employee_id => @person.id}, :order => 'key asc')
        assert_difference('IdxEmployeesText.count', 0) do
          @person.update_attributes('name' => 'Xavier')
        end

        high_index = IdxEmployeesText.find(high_index.id) # reload (make sure the record has been updated, not recreated)
        name_index = IdxEmployeesText.find(name_index.id) # reload (make sure the record has been updated, not recreated)

        assert_equal 'high', high_index.key
        assert_equal 'gender:M age:34 name:Xavier', high_index.value
        assert_equal 'name_es', name_index.key
        assert_equal 'Xavier', name_index.value
      end

      context 'with key alterations' do
        should 'remove and create new keys' do
          high_index, name_index = IdxEmployeesText.all(:conditions => {:employee_id => @person.id}, :order => 'key asc')
          assert_difference('IdxEmployeesText.count', 0) do
            @person.update_attributes('lang' => 'en', 'name' => 'John')
          end

          assert IdxEmployeesText.find(high_index.id)
          assert_nil IdxEmployeesText.find_by_id(name_index.id)

          high_index, name_index = IdxEmployeesText.all(:conditions => {:employee_id => @person.id}, :order => 'key asc')

          assert_equal 'high', high_index.key
          assert_equal 'gender:M age:34 name:John', high_index.value
          assert_equal 'name_en', name_index.key
          assert_equal 'John', name_index.value
        end
      end
    end

    context 'on record destruction' do
      should 'remove index entries' do
        person = Person.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
        assert_difference('IdxEmployeesText.count', -2) do
          assert_difference('IdxEmployeesInteger.count', -1) do
            person.destroy
          end
        end
      end
    end
  end
end