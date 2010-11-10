module IndexMacros
  # Simple class
  class Client < ActiveRecord::Base
    set_table_name :employees
    include Property
    
    def muse
      'I am your muse'
    end
    def index_reader(group_name)
      if group_name.to_s == 'ml_string'
        super.merge(:with => {'lang' => ['en', 'fr'], 'site_id' => '123'})
      else
        super
      end
    end
  end
end

class Test::Unit::TestCase

  def self.should_maintain_indices

    context "assigned to an instance of Dummy" do
      subject do
        dummy = IndexMacros::Client.new
        dummy.include_role @poet
        dummy
      end

      should 'use index_reader method' do
        assert_equal Hash[:with=>{'lang'=>['en', 'fr'], 'site_id'=>'123'}, "employee_id"=>nil], subject.index_reader(:ml_string)
      end

      should 'create multilingual string indices on save' do
        assert_difference('IdxEmployeesMlString.count', 2) do
          subject.poem = 'Hyperions Schicksalslied'
          subject.save
        end
      end

      should 'create integer indices on save' do
        assert_difference('IdxEmployeesInteger.count', 1) do
          subject.year = 1770
          subject.save
        end
      end

      should 'not create blank indices on save' do
        assert_difference('IdxEmployeesString.count', 0) do
          assert_difference('IdxEmployeesInteger.count', 0) do
            subject.save
          end
        end
      end
    end # An instance of Person
  end

  def self.should_not_maintain_indices

    context "assigned to an instance of Dummy" do
      subject do
        dummy = IndexMacros::Client.new
        dummy.include_role @poet
        dummy
      end

      should 'not create indices on save' do
        assert_difference('IdxEmployeesString.count', 0) do
          assert_difference('IdxEmployeesInteger.count', 0) do
            subject.year = 1770
            subject.poem = 'Hyperions Schicksalslied'
            subject.save
          end
        end
      end

      should 'not create blank indices on save' do
        assert_difference('IdxEmployeesString.count', 0) do
          assert_difference('IdxEmployeesInteger.count', 0) do
            subject.save
          end
        end
      end
    end # An instance of Person
  end
end