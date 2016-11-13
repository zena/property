require 'syck'
module Property
  module Serialization
    # Use YAML to encode properties. This method is the slowest of all
    # and you should use JSON if you haven't got good reasons not to.
    module YAML
      def self.included(base)
        base.extend Encoder
      end

      module Encoder
        # Encode properties with Marhsal
        def encode_properties(properties)
          ::Syck.dump(properties)
        end

        # Decode Marshal encoded properties
        def decode_properties(string)
          ::Syck.load(string)
        end
      end # Encoder
      include Encoder
      extend Encoder

    end # Yaml
  end # Serialization
end # Property