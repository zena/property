require 'test_helper'
require 'fixtures'

class BehaviorTest < Test::Unit::TestCase

  should_store_property_definitions(Property::Behavior)


  context 'A Poet Behavior' do
    setup do
      @poet = Property::Behavior.new('Poet') do |p|
        p.string 'poem', :default => :muse

        p.actions do
          def muse
            'I am your muse'
          end
        end
      end
    end

    should_insert_properties_on_behave_like_poet
    should_add_behavior_methods
    should_take_part_in_used_list
  end
end