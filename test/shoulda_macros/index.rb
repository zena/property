module IndexMacros
  class IndexedStringEmp < ActiveRecord::Base
    set_table_name :i_string_employees
  end

  class IndexedIntegerEmp < ActiveRecord::Base
    set_table_name :i_integer_employees
  end

  # Simple class
  class Employee < ActiveRecord::Base
    include Property
  end
end

class Test::Unit::TestCase

  def self.should_maintain_indices

    context "assigned to an instance of Dummy" do
      subject do
        dummy = IndexMacros::Employee.new
        dummy.has_role @poet
        dummy
      end

      should 'write tests for :with option' do
        assert false
      end

      should 'create string indices on save' do
        assert_difference('IndexMacros::IndexedStringEmp.count', 1) do
          subject.poem = 'Hyperions Schicksalslied'
          subject.save
        end
      end

      should 'create integer indices on save' do
        assert_difference('IndexMacros::IndexedIntegerEmp.count', 1) do
          subject.year = 1770
          subject.save
        end
      end

      should 'not create blank indices on save' do
        assert_difference('IndexMacros::IndexedStringEmp.count', 0) do
          assert_difference('IndexMacros::IndexedIntegerEmp.count', 0) do
            subject.save
          end
        end
      end
    end # An instance of Person
  end

  def self.should_not_maintain_indices

    context "assigned to an instance of Dummy" do
      subject do
        dummy = IndexMacros::Employee.new
        dummy.has_role @poet
        dummy
      end

      should 'not create indices on save' do
        assert_difference('IndexMacros::IndexedStringEmp.count', 0) do
          assert_difference('IndexMacros::IndexedIntegerEmp.count', 0) do
            subject.year = 1770
            subject.poem = 'Hyperions Schicksalslied'
            subject.save
          end
        end
      end

      should 'not create blank indices on save' do
        assert_difference('IndexMacros::IndexedStringEmp.count', 0) do
          assert_difference('IndexMacros::IndexedIntegerEmp.count', 0) do
            subject.save
          end
        end
      end
    end # An instance of Person
  end
end