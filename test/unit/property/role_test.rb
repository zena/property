require 'test_helper'
require 'fixtures'

class RoleTest < Test::Unit::TestCase

  should_store_property_definitions(Property::Role)


  context 'A Poet Role' do
    setup do
      @poet = Property::Role.new('Poet') do |p|
        p.string 'poem', :default => :muse

        p.actions do
          def muse
            'I am your muse'
          end
        end
      end
    end

    should_insert_properties_on_has_role_poet
    should_add_role_methods
    should_take_part_in_used_list
  end
end