require 'test_helper'
require 'fixtures'

# including Property::Base is like including Property but without hooks
class BaseTest < Test::Unit::TestCase

  context 'An external storage including property base' do
    class Version < ActiveRecord::Base
      include Property::Base
      belongs_to :contact, :class_name => 'BaseTest::Contact',
                 :foreign_key => 'employee_id'
      property do |p|
        p.string 'first_name'
      end
    end

    class Contact < ActiveRecord::Base
      set_table_name :employees
      has_many :versions, :class_name => 'BaseTest::Version'

      include Property
      store_properties_in :version

      property do |p|
        p.string 'first_name'
        p.string 'name'
      end

      def version
        @version ||= begin
          if new_record?
            versions.build
          else
            Version.first(:conditions => ['employee_id = ?', self.id]) || versions.build
          end
        end
      end
    end

    context 'with properties' do
      setup do
        contact = Contact.create('first_name' => 'Angela', 'name' => 'Davis')
        @version = Version.find(contact.version.id)
      end

      should 'unpack and read properties' do
        assert_equal 'Angela', @version.first_name
      end

      should 'not execute save hooks' do
        @version.prop['first_name'] = 'Angel'
        assert @version.save
        @version = Version.find(@version)
        assert_equal 'Angela', @version.first_name
      end

      should 'not only have accessors for properties defined in self' do
        assert_raise(ActiveRecord::UnknownAttributeError) do
          @version.update_attributes('name' => 'Crenshaw')
        end
      end
    end
  end
end
















