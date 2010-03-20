require 'test_helper'
require 'fixtures'

class IndexCustomTest < ActiveSupport::TestCase
  class IndexedContact < ActiveRecord::Base
    set_table_name :contacts

    def self.set_property_index(person, indexes)
      if index = first(:conditions => ['employee_id = ?', person.id])
        index.update_attributes(indexes)
      else
        create(indexes.merge(:employee_id => person.id))
      end
    end

    def self.delete_property_index(person)
      delete_all(['employee_id = ?', person.id])
    end
  end

  # Index definition class with a legacy table for indexes
  class Person < ActiveRecord::Base
    include Property
    set_table_name :employees

    property do |p|
      p.string 'name'
      p.string 'first_name'

      p.index(IndexedContact) do |r| # r = record
        {
          'name' => "#{r.name}!", # just to test renaming
          'other_name' => r.first_name
        }
      end
    end
  end

  context 'A schema from a class with a custom indexer' do
    subject do
      Person.schema
    end

    should 'return a Hash on index_groups' do
      assert_kind_of Hash, subject.index_groups
    end

    should 'group indexes by type' do
      assert_equal %w{IndexCustomTest::IndexedContact}, subject.index_groups.keys.map(&:to_s).sort
    end
  end

  context 'A class with complex index definition' do
    subject do
      Person
    end

    context 'on record creation' do
      should 'create index entries in the custom table' do
        assert_difference('IndexedContact.count', 1) do
          Person.create('name' => 'Sadr', 'first_name' => 'Shadi')
        end
      end

      should 'store key and value pairs linked to the model' do
        person = Person.create('name' => 'Sadr', 'first_name' => 'Shadi')
        index  = IndexedContact.first(:conditions => {:employee_id => person.id})
        assert_equal 'Sadr!', index.name
        assert_equal 'Shadi', index.other_name
      end
    end

    context 'on record update' do
      setup do
        @person = Person.create('name' => 'Sadr', 'first_name' => 'Shadi')
      end

      should 'update index entries' do
        index  = IndexedContact.first(:conditions => {:employee_id => @person.id})
        assert_difference('IndexedContact.count', 0) do
          @person.update_attributes('first_name' => 'Shiva', 'name' => 'Nazar Ahari')
        end

        index = IndexedContact.find(index.id) # reload (make sure the record has been updated, not recreated)

        assert_equal 'Nazar Ahari!', index.name
        assert_equal 'Shiva', index.other_name
      end
    end

    context 'on record destruction' do
      should 'remove index entry' do
        person = Person.create('first_name' => 'Gaspard', 'name' => 'Bucher')
        assert_difference('IndexedContact.count', -1) do
          person.destroy
        end
      end
    end
  end
end