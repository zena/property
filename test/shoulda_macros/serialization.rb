class Test::Unit::TestCase

  def self.should_encode_and_decode_properties
    klass = self.name.gsub(/Test$/,'').constantize

    context "Instance of #{klass}" do
      setup do
        @obj = klass.new
      end

      should 'respond to :encode_properties' do
        assert @obj.respond_to? :encode_properties
      end

      should 'respond to :decode_properties' do
        assert @obj.respond_to? :decode_properties
      end

      context 'with Properties' do
        setup do
          @properties = Property::Properties[
            'string'     => "one\ntwo",
            'serialized' => Cat.new('Pavlov', 'Freud'),
            'datetime'   => Time.utc(2010, 02, 12, 21, 31, 25),
            'float'      => 4.3432,
            'integer'    => 4
          ]
        end

        should 'encode Properties in string' do
          assert_kind_of String, @obj.encode_properties(@properties)
        end

        should 'restore Properties from string' do
          string = @obj.encode_properties(@properties)
          properties = @obj.decode_properties(string)
          assert_equal Property::Properties, properties.class
          assert_equal @properties, properties
        end

        context 'with ascii 18' do
          subject do
            Property::Properties[
              'string' => (1..255).to_a.map{|n| n.chr}.join('') # "AB"
            ]
          end

          should 'encode and decode ascii 18' do
            string = @obj.encode_properties(subject)
            properties = @obj.decode_properties(string)
            assert_equal Property::Properties, properties.class
            assert_equal subject, properties
          end
        end # with ascii 18


        should 'not include instance variables' do
          @properties.instance_eval do
            @baz   = 'some data'
            @owner = klass.new
          end
          prop = @obj.decode_properties(@obj.encode_properties(@properties))
          assert_nil prop.instance_variable_get(:@baz)
          assert_nil prop.instance_variable_get(:@owner)
        end
      end

      context 'with empty Properties' do
        setup do
          @properties = Property::Properties.new
        end

        should 'encode and decode' do
          string = @obj.encode_properties(@properties)
          properties = @obj.decode_properties(string)
          assert_equal Property::Properties, properties.class
          assert_equal @properties, properties
        end
      end
    end
  end
end