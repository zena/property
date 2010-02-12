module Property

  # Property::Declaration module is used to declare property definitions in a Class. The module
  # also manages property inheritence in sub-classes.
  module Declaration

    def self.included(base)
      base.class_eval do
        extend  ClassMethods
        include InstanceMethods

        class << self
          attr_accessor :schema

          def schema
            @schema ||= begin
              schema = Property::Schema.new(self.to_s)
              if superclass.respond_to?(:schema)
                schema.behave_like superclass
              end
              schema
            end
          end
        end

        validate :properties_validation, :if => :properties
      end
    end

    module ClassMethods

      # Include a new set of property definitions (Behavior) into the current class schema.
      # You can also provide a class to simulate multiple inheritance.
      def behave_like(behavior)
        schema.behave_like behavior
        #
        # define_property_methods(column) if column.should_create_accessors?
      end

      # Use this class method to declare properties that will be used in your models.
      # Example:
      #  property.string 'phone', :default => ''
      #
      # You can also use a block:
      #  property do |p|
      #    p.string 'phone', 'name', :default => ''
      #  end
      def property
        setter = schema.behavior

        if block_given?
          yield setter
        end

        setter
      end

      def define_property_methods(column)
        name = column.name
        unless instance_method_already_implemented?(name)
          if create_time_zone_conversion_attribute?(name, column)
            define_read_property_method_for_time_zone_conversion(name)
          else
            define_read_property_method(name.to_sym, name, column)
          end
        end

        unless instance_method_already_implemented?("#{name}=")
          if create_time_zone_conversion_attribute?(name, column)
            define_write_property_method_for_time_zone_conversion(name)
          else
            define_write_property_method(name.to_sym)
          end
        end

        unless instance_method_already_implemented?("#{name}?")
          define_question_property_method(name)
        end
      end

      private
        # Define a property reader method.  Cope with nil column.
        def define_read_property_method(symbol, attr_name, column)
          # Unlike rails, we do not cast on read
          evaluate_attribute_property_method attr_name, "def #{symbol}; prop['#{attr_name}']; end"
        end

        # Defined for all +datetime+ and +timestamp+ attributes when +time_zone_aware_attributes+ are enabled.
        # This enhanced read method automatically converts the UTC time stored in the database to the time zone stored in Time.zone.
        def define_read_property_method_for_time_zone_conversion(attr_name)
          method_body = <<-EOV
            def #{attr_name}(reload = false)
              cached = @attributes_cache['#{attr_name}']
              return cached if cached && !reload
              time = properties['#{attr_name}']
              @attributes_cache['#{attr_name}'] = time.acts_like?(:time) ? time.in_time_zone : time
            end
          EOV
          evaluate_attribute_property_method attr_name, method_body
        end

        # Defines a predicate method <tt>attr_name?</tt>.
        def define_question_property_method(attr_name)
          evaluate_attribute_property_method attr_name, "def #{attr_name}?; prop['#{attr_name}']; end", "#{attr_name}?"
        end

        def define_write_property_method(attr_name)
          evaluate_attribute_property_method attr_name, "def #{attr_name}=(new_value);prop['#{attr_name}'] = new_value; end", "#{attr_name}="
        end

        # Defined for all +datetime+ and +timestamp+ attributes when +time_zone_aware_attributes+ are enabled.
        # This enhanced write method will automatically convert the time passed to it to the zone stored in Time.zone.
        def define_write_property_method_for_time_zone_conversion(attr_name)
          method_body = <<-EOV
            def #{attr_name}=(time)
              unless time.acts_like?(:time)
                time = time.is_a?(String) ? Time.zone.parse(time) : time.to_time rescue time
              end
              time = time.in_time_zone rescue nil if time
              prop['#{attr_name}'] = time
            end
          EOV
          evaluate_attribute_property_method attr_name, method_body, "#{attr_name}="
        end

        # Evaluate the definition for an attribute related method
        def evaluate_attribute_property_method(attr_name, method_definition, method_name=attr_name)
          class_eval(method_definition, __FILE__, __LINE__)
        end
    end # ClassMethods

    module InstanceMethods
      # Instance's schema (can be different from the instance's class schema if behaviors have been
      # added to the instance.
      def schema
        @own_schema || self.class.schema
      end

      # Include a new set of property definitions (Behavior) into the current instance's schema.
      # You can also provide a class to simulate multiple inheritance.
      def behave_like(behavior)
        own_schema.behave_like behavior
      end

      protected
        def properties_validation
          properties.validate
        end

        def own_schema
          @own_schema ||= begin
            schema = Property::Schema.new
            schema.behave_like self.class
            schema
          end
        end
    end # InsanceMethods
  end # Declaration
end # Property