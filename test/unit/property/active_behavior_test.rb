require 'test_helper'
require 'fixtures'

class ActiveBehaviorTest < ActiveSupport::TestCase
  ActiveBehavior = Property::ActiveBehavior
  BehaviorColumn = Property::BehaviorColumn

  should_store_property_definitions(ActiveBehavior)

  context 'A stored ActiveBehavior' do

    context 'with column definitions' do
      setup do
        behavior = ActiveBehavior.create(:name => 'Poet')
        behavior.behavior_columns << BehaviorColumn.new(:ptype => 'string',  :name => 'poem')
        behavior.save!
        @poet = ActiveBehavior.find(behavior.id)
      end

      should_insert_properties_on_behave_like_poet

      should 'create new behavior columns on save' do
        @poet.property do |p|
          p.integer 'year'
        end

        assert_difference('ActiveBehavior.count', 0) do
          assert_difference('BehaviorColumn.count', 1) do
            @poet.save
          end
        end
      end
    end # with column definitions
  end # A stored ActiveBehavior

  context 'A new ActiveBehavior' do
    subject do
      ActiveBehavior.new('Poet') do |p|
        p.string 'name'
      end
    end

    should 'define properties with a block' do
      assert_equal %w{name}, subject.column_names
    end

    should 'create behavior columns on save' do
      behavior = subject
      assert_difference('ActiveBehavior.count', 1) do
        assert_difference('BehaviorColumn.count', 1) do
          behavior.save
        end
      end
    end
  end # A new ActiveBehavior
end
