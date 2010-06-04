require 'test_helper'
class AttributeTest < Test::Unit::TestCase

  context 'Creating Column instances' do
    context 'without index' do
      subject do
        Property::Column.new('name', nil, 'string', {})
      end

      should 'set index to nil' do
        assert_nil subject.index
      end
    end # without index

    context 'with index true' do
      subject do
        Property::Column.new('foo', nil, 'string', {:index => true})
      end

      should 'set index to type' do
        assert_equal 'string', subject.index
      end
      
      context 'and an index_group' do
        subject do
          Property::Column.new('foo', nil, 'string', {:index => true, :index_group => :integer})
        end

        should 'set index to index_group' do
          assert_equal 'integer', subject.index
        end
      end # and an index_group
    end # with index true

    
    context 'with an index name' do
      subject do
        Property::Column.new('foo', nil, 'string', {:index => :special})
      end

      should 'set index to index name' do
        assert_equal 'special', subject.index
      end
    end # with an index name
    
    context 'with an index proc' do
      subject do
        Property::Column.new('foo', nil, 'string', {:index => Proc.new{}})
      end

      should 'set index to type' do
        assert_equal 'string', subject.index
      end
      
      context 'and an index_group' do
        subject do
          Property::Column.new('foo', nil, 'string', {:index => Proc.new{}, :index_group => :ml_string})
        end

        should 'set index to index_group' do
          assert_equal 'ml_string', subject.index
        end
      end # and an index_group
    end # with an index proc
  end # Creating Column instances
end
