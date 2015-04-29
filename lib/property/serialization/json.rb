unless ::JSON::VERSION == "1.5.1"
  puts "###################################################################"
  puts "ERROR:   --- property ---"
  puts "         JSON serialization only works with JSON 1.5.1"
  puts "         current JSON version is #{::JSON::VERSION}"
  puts "###################################################################"
end
gem 'json', '=1.5.1'
module Property
  module Serialization
    # Use JSON to encode properties. This is the serialization best option. It's
    # the fastest and does not have any binary format issues. You just have to
    # provide 'self.create_json' and 'to_json' methods for the classes you want
    # to serialize.
    module JSON
      module Validator
        NATIVE_TYPES = [Hash, Array, Integer, Float, String, TrueClass, FalseClass, NilClass]

        if RUBY_VERSION.to_f > 1.8
          # Should raise an exception if the type is not serializable.
          def self.validate(klass)
            if NATIVE_TYPES.include?(klass) ||
               (klass.respond_to?(:json_create) && klass.instance_methods.include?(:to_json))
              true
            else
              raise TypeError.new("Cannot serialize #{klass}. Missing 'self.create_json' and 'to_json' methods.")
            end
          end
        else
          # Should raise an exception if the type is not serializable.
          def self.validate(klass)
            if NATIVE_TYPES.include?(klass) ||
               (klass.respond_to?('json_create') && klass.instance_methods.include?('to_json'))
              true
            else
              raise TypeError.new("Cannot serialize #{klass}. Missing 'self.create_json' and 'to_json' methods.")
            end
          end
        end
      end

      def self.included(base)
        Property.validators << Validator
        base.extend Encoder
      end

      module Encoder
        # Encode properties with JSON
        def encode_properties(properties)
          ::JSON.dump(properties)
        end

        # Decode JSON encoded properties
        def decode_properties(string)
          ::JSON.parse(string)
        end
      end # Encoder
      include Encoder
      extend Encoder
    end # JSON
  end # Serialization
end # Property
