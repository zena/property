YAML::ENGINE.yamler = 'syck' # only for ruby 1.9.3

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
          ::YAML.dump(properties)
        end

        # Decode Marshal encoded properties
        def decode_properties(string)
          ::YAML::load(string)
        end
      end # Encoder
      include Encoder
      extend Encoder

    end # Yaml
  end # Serialization
end # Property