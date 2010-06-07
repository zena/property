module Property
  module Serialization
    # Use Marhsal to encode properties. Unless you have very good reasons
    # to use Marshal, you should use the JSON serialization instead:
    #  * it's faster at reading text/date based objects
    #  * it's human readable
    #  * no corruption risk if the version of Marshal changes
    #  * it can be accessed by other languages then ruby
    module Marshal
      def self.included(base)
        base.extend Encoder
      end

      module Encoder
        # Encode properties with Marhsal
        def encode_properties(properties)
          # we limit dump depth to 0 (object only: no instance variables)
          # we have to protect Marshal from serializing instance variables by making a copy
          [::Marshal::dump(Properties[properties])].pack('m*')
        end

        # Decode Marshal encoded properties
        def decode_properties(string)
          ::Marshal::load(string.unpack('m')[0])
        end
      end # Encoder
      include Encoder
      extend Encoder

    end # Marshal
  end # Serialization
end # Property