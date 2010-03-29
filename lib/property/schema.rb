
module Property
  # This class holds all the properties of a given class or instance. It is used
  # to validate content and type_cast during write operations.
  #
  # The properties are not directly defined in the schema. They are stored in a
  # Behavior instance which checks that the database is in sync with the properties
  # defined.
  class Schema
    attr_reader :behaviors, :behavior, :binding

    # Create a new Schema. If a class_name is provided, the schema automatically
    # creates a default Behavior to store definitions.
    def initialize(class_name, binding)
      @binding = binding
      @behaviors = []
      if class_name
        @behavior  = Behavior.new(class_name)
        include_behavior @behavior
        @behaviors << @behavior
      end
    end

    # Return an identifier for the schema to help locate property redefinition errors.
    def name
      @behavior ? @behavior.name : @binding.to_s
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
          schema_class = thing.schema.binding
          if @binding.ancestors.include?(schema_class)
            check_super_methods = false
          else
            check_super_methods = true
          end
          thing.schema.behaviors.flatten.each do |behavior|
            include_behavior behavior, check_super_methods
          end
          self.behaviors << thing.schema.behaviors
        else
          raise TypeError.new("expected Behavior or class with schema, found #{thing}")
        end
      elsif thing.kind_of?(Behavior)
        include_behavior thing
        self.behaviors << thing
      else
        raise TypeError.new("expected Behavior or class with schema, found #{thing.class}")
      end
    end

    # Return the list of column names.
    def column_names
      columns.keys
    end

    # Return true if the schema has a property with the given name.
    def has_column?(name)
      name = name.to_s
      [@behaviors].flatten.each do |behavior|
        return true if behavior.has_column?(name)
      end
      false
    end

    # Return column definitions from all included behaviors.
    def columns
      columns = {}
      @behaviors.flatten.uniq.each do |b|
        columns.merge!(b.columns)
      end
      columns
    end

    # Return a hash with indexed types as keys and index definitions as values.
    def index_groups
      index_groups = {}
      @behaviors.flatten.uniq.each do |b|
        b.indices.each do |list|
          (index_groups[list.first] ||= []) << list[1..-1]
        end
      end
      index_groups
    end

    private
      def include_behavior(behavior, check_methods = true)
        return if behaviors.include?(behavior)
        behavior_column_names = behavior.column_names

        check_duplicate_property_definitions(behavior, behavior_column_names)
        check_duplicate_method_definitions(behavior, behavior_column_names) if check_methods

        behavior.included(self)
        @binding.send(:include, behavior.accessor_module)
      end

      def check_duplicate_property_definitions(behavior, keys)
        common_keys = keys & self.columns.keys
        if !common_keys.empty?
          raise RedefinedPropertyError.new("Cannot include behavior '#{behavior.name}' in '#{name}'. Duplicate definitions: #{common_keys.join(', ')}")
        end
      end

      def check_duplicate_method_definitions(behavior, keys)
        common_keys = []
        keys.each do |k|
          common_keys << k if @binding.superclass.method_defined?(k)
        end

        if !common_keys.empty?
          raise RedefinedMethodError.new("Cannot include behavior '#{behavior.name}' in '#{@binding}'. Would hide methods in superclass: #{common_keys.join(', ')}")
        end
      end

  end
end
