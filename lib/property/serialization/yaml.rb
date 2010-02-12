module Property
  module Serialization
    # Use YAML to encode properties. This method is the slowest of all
    # and you should use JSON if you haven't got good reasons not to.
    module YAML
      # Encode properties with YAML
      def encode_properties(properties)
        ::YAML.dump(properties)
      end

      # Decode properties from YAML
      def decode_properties(string)
        ::YAML::load(string)
      end

    end # Yaml
  end # Serialization
end # Property