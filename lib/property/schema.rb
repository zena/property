
module Property
  # This class holds all the properties of a given class or instance. It is used
  # to validate content and type_cast during write operations.
  #
  # The properties are not directly defined in the schema. They are stored in a
  # Behavior instance which checks that the database is in sync with the properties
  # defined.
  class Schema
    attr_reader :behaviors, :behavior

    # Create a new Schema. If a class_name is provided, the schema automatically
    # creates a default Behavior to store definitions.
    def initialize(class_name = nil)
      if class_name
        @behavior  = Behavior.new(class_name)
        @behaviors = [@behavior]
      else
        @behaviors = []
      end
    end

    # If the parameter is a class, the schema will inherit the property definitions
    # from the class. If the parameter is a Behavior, the properties from that
    # behavior will be included. Any new columns added to a behavior or any new
    # behaviors included in a class will be dynamically added to the sub-classes (just like
    # Ruby class inheritance, module inclusion works).
    # If you ...
    def behave_like(behaviors)
      if behaviors.kind_of?(Class)
        if behaviors.respond_to?(:schema) && behaviors.schema.kind_of?(Schema)
          #behaviors.schema.behaviors.each |behavior|
          #  include_behavior(behavior)
          #end
          @behaviors << behaviors.schema.behaviors
        else
          raise "Cannot insert behaviors from #{behaviors} (no 'schema')"
        end
      elsif behaviors.kind_of?(Schema)
        @behaviors << behaviors.behaviors
      else
        @behaviors << behaviors
      end
    end

    # Return the list of column names.
    def column_names
      columns.keys
    end

    # Return all column definitions from all ancestors. This method does not memoize
    # the result so you should not call it in a loop.
    def columns
      columns = {}
      behaviors.flatten.uniq.reverse_each do |behavior|
        columns.merge!(behavior.columns)
      end
      columns
    end
  end
end
