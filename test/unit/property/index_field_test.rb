require 'test_helper'
require 'fixtures'

class IndexFieldTest < ActiveSupport::TestCase

  class Person < ActiveRecord::Base
    include Property
    set_table_name :employees
    property.string 'name'
    property.float 'age', :index => '.idx_float1'
  end

  context 'A class with a field index' do
    subject do
      Person
    end

    context 'on record creation' do
      should 'succeed' do
        assert_difference('Person.count', 1) do
          Person.create('name' => 'Jake Sully', 'age' => 30)
        end
      end

      should 'save index in the model' do
        person = Person.create('name' => 'Jake Sully', 'age' => 30)
        assert_equal 30, Person.find(person.id).idx_float1
      end
    end

    context 'on record update' do
      subject do
        Person.create('name' => 'Jake Sully', 'age' => 30)
      end

      should 'update index entries' do
        subject.update_attributes('age' => 15)
        assert_equal 15, Person.find(subject).idx_float1
      end
    end

    context 'on index rebuild' do
      subject do
        p = Person.create('name' => 'Jake Sully', 'age' => 30)
        Person.connection.execute "UPDATE #{Person.table_name} SET idx_float1 = NULL"
        Person.find(p)
      end

      should 'rebuild field index' do
        subject.rebuild_index!
        assert_equal 30, Person.find(subject.id).idx_float1
      end
    end # on index rebuild

    context 'on record destroy' do
      subject do
        Person.create('name' => 'Jake Sully', 'age' => 30)
      end

      should 'not raise an error' do
        subject # create
        assert_difference('Person.count', -1) do
          assert_nothing_raised do
            assert subject.destroy
          end
        end
      end
    end
  end
end