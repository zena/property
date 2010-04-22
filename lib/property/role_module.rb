require 'property/redefined_property_error'
require 'property/redefined_method_error'

module Property
  # This class holds a set of property definitions. This is like a Module in ruby:
  # by 'including' this role in a class or in an instance, you augment the said
  # object with the role's property definitions.
  module RoleModule
    def self.included(base)
      base.send(:attr_accessor, :name, :included, :accessor_module)
    end

    # Initialize module (should be called from within including class's initialize method).
    def initialize_role_module
      @included_in_schemas = []
      @group_indices   = []
      @accessor_module = build_accessor_module
    end

    # List all property definitiosn for the current role
    def columns
      @columns ||= {}
    end

    # Return a list of index definitions in the form [type, key, proc_or_nil]
    def indices
      columns.values.select do |c|
        c.indexed?
      end.map do |c|
        if c.index == true
          [c.type, c.name]
        else
          [c.type, c.name, c.index]
        end
      end + @group_indices
    end

    # Return true if the Role contains the given column (property).
    def has_column?(name)
      column_names.include?(name)
    end

    # Return the list of column names.
    def column_names
      columns.keys
    end

    # Use this method to declare properties into a Role.
    # Example:
    #  @role.property.string 'phone', :default => ''
    #
    # You can also use a block:
    #  @role.property do |p|
    #    p.string 'phone', 'name', :default => ''
    #  end
    def property
      if block_given?
        yield accessor_module
      end
      accessor_module
    end

    # @internal
    # This is called when the role is included in a schema
    def included_in(schema)
      @included_in_schemas << schema
    end

    # @internal
    def add_column(column)
      name = column.name

      if columns[name]
        raise RedefinedPropertyError.new("Property '#{name}' is already defined.")
      else
        verify_not_defined_in_schemas_using_this_role(name)
        verify_method_not_defined_in_classes_using_this_role(name)
        define_property_methods(column) if column.should_create_accessors?
        columns[column.name] = column
      end
    end

    # @internal
    def add_index(type, proc)
      #                 type,  key, proc
      @group_indices << [type, nil, proc]
    end

    # Returns true if the current role is used by the given object. A Role is
    # considered to be used if any of it's attributes is not blank in the object's
    # properties.
    def used_in(object)
      used_keys_in(object) != []
    end

    # Returns the list of column names in the current role that are used by the
    # given object (value not blank).
    def used_keys_in(object)
      object.properties.keys & column_names
    end

    private
      def build_accessor_module
        accessor_module = Module.new
        accessor_module.class_eval do
          class << self
            attr_accessor :role

            # def string(*args)
            #   options = args.extract_options!
            #   column_names = args
            #   default = options.delete(:default)
            #   column_names.each { |name| column(name, default, 'string', options) }
            # end
            %w( string text integer float decimal datetime timestamp time date binary boolean ).each do |column_type|
              class_eval <<-EOV
                def #{column_type}(*args)
                  options = args.extract_options!
                  column_names = args.flatten
                  default = options.delete(:default)
                  column_names.each { |name| role.add_column(Property::Column.new(name, default, '#{column_type}', options)) }
                end
              EOV
            end

            # This is used to serialize a non-native DB type. Use:
            #   p.serialize 'pet', Dog
            def serialize(name, klass, options = {})
              Property.validate_property_class(klass)
              role.add_column(Property::Column.new(name, nil, klass, options))
            end

            # This is used to create complex indices with the following syntax:
            #
            #   p.index(:text) do |r| # r = record
            #     {
            #       "high"           => "gender:#{r.gender} age:#{r.age} name:#{r.name}",
            #       "name_#{r.lang}" => r.name, # multi-lingual index
            #     }
            #   end
            #
            # The first argument is the type (used to locate the table where the data will be stored) and the block
            # will be yielded with the record and should return a hash of key => value pairs.
            def index(type, &block)
              role.add_index(type, block)
            end

            alias actions class_eval
          end
        end
        accessor_module.role = self
        accessor_module
      end

      def define_property_methods(column)
        name = column.name

        #if create_time_zone_conversion_attribute?(name, column)
        #  define_read_property_method_for_time_zone_conversion(name)
        #else
        define_read_property_method(name.to_sym, name, column)
        #end

        #if create_time_zone_conversion_attribute?(name, column)
        #  define_write_property_method_for_time_zone_conversion(name)
        #else
        define_write_property_method(name.to_sym)
        #end

        define_question_property_method(name)
      end

      # Define a property reader method.  Cope with nil column.
      def define_read_property_method(symbol, attr_name, column)
        # Unlike rails, we do not cast on read
        evaluate_attribute_property_method attr_name, "def #{symbol}; prop['#{attr_name}']; end"
      end

      # Defined for all +datetime+ and +timestamp+ attributes when +time_zone_aware_attributes+ are enabled.
      # This enhanced read method automatically converts the UTC time stored in the database to the time zone stored in Time.zone.
      # def define_read_property_method_for_time_zone_conversion(attr_name)
      #   method_body = <<-EOV
      #     def #{attr_name}(reload = false)
      #       cached = @attributes_cache['#{attr_name}']
      #       return cached if cached && !reload
      #       time = properties['#{attr_name}']
      #       @attributes_cache['#{attr_name}'] = time.acts_like?(:time) ? time.in_time_zone : time
      #     end
      #   EOV
      #   evaluate_attribute_property_method attr_name, method_body
      # end

      # Defines a predicate method <tt>attr_name?</tt>.
      def define_question_property_method(attr_name)
        evaluate_attribute_property_method attr_name, "def #{attr_name}?; prop['#{attr_name}']; end", "#{attr_name}?"
      end

      def define_write_property_method(attr_name)
        evaluate_attribute_property_method attr_name, "def #{attr_name}=(new_value);prop['#{attr_name}'] = new_value; end", "#{attr_name}="
      end

      # Defined for all +datetime+ and +timestamp+ attributes when +time_zone_aware_attributes+ are enabled.
      # This enhanced write method will automatically convert the time passed to it to the zone stored in Time.zone.
      # def define_write_property_method_for_time_zone_conversion(attr_name)
      #   method_body = <<-EOV
      #     def #{attr_name}=(time)
      #       unless time.acts_like?(:time)
      #         time = time.is_a?(String) ? Time.zone.parse(time) : time.to_time rescue time
      #       end
      #       time = time.in_time_zone rescue nil if time
      #       prop['#{attr_name}'] = time
      #     end
      #   EOV
      #   evaluate_attribute_property_method attr_name, method_body, "#{attr_name}="
      # end

      # Evaluate the definition for an attribute related method
      def evaluate_attribute_property_method(attr_name, method_definition, method_name=attr_name)
        accessor_module.class_eval(method_definition, __FILE__, __LINE__)
      end

      def verify_not_defined_in_schemas_using_this_role(name)
        @included_in_schemas.each do |schema|
          if schema.columns[name]
            raise RedefinedPropertyError.new("Property '#{name}' is already defined in #{schema.name}.")
          end
        end
      end

      def verify_method_not_defined_in_classes_using_this_role(name)
        @included_in_schemas.each do |schema|
          if schema.binding.superclass.method_defined?(name)
            raise RedefinedMethodError.new("Method '#{name}' is already defined in #{schema.binding.superclass} or ancestors.")
          end
        end
      end
  end
end
