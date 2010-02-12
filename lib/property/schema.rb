
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
    def initialize(class_name, binding)
      @binding = binding
      if class_name
        @behavior  = Behavior.new(class_name, self)
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
    def behave_like(thing)
      if thing.kind_of?(Class)
        if thing.respond_to?(:schema) && thing.schema.kind_of?(Schema)
          thing.schema.behaviors.each do |behavior|
            include_behavior behavior
          end
        else
          raise TypeError.new("expected Behavior or class with schema, found #{thing}")
        end
      elsif thing.kind_of?(Behavior)
        include_behavior thing
      else
        raise TypeError.new("expected Behavior or class with schema, found #{thing.class}")
      end
    end

    # Return the list of column names.
    def column_names
      columns.keys
    end

    # Return column definitions from all included behaviors.
    def columns
      @columns ||= {}
    end

    # @internal
    def add_column(column)
      raise TypeError.new("Property '#{column.name}' is already defined.") if columns.keys.include?(column.name)
      add_column_without_check(column)
    end

    private
      def add_column_without_check(column)
        columns[column.name] = column
        if column.should_create_accessors?
          @binding.define_property_methods(column)
        end
      end

      def include_behavior(behavior)
        columns = self.columns

        common_keys = behavior.column_names & columns.keys
        if !common_keys.empty?
          raise TypeError.new("Cannot include behavior #{behavior.name}. Duplicate definitions: #{common_keys.join(', ')}")
        end

        behavior.columns.each do |name, column|
          add_column_without_check(column)
        end

        self.behaviors << behavior

        behavior.included = true
      end
  end
end
