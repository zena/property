module Property

  # Property::Declaration module is used to declare property definitions in a Class. The module
  # also manages property inheritence in sub-classes.
  module Declaration

    def self.included(base)
      base.class_eval do
        extend  ClassMethods
        include InstanceMethods

        class << self
          attr_accessor :own_property_columns
          attr_accessor :property_definition_proxy
        end

        validate :properties_validation, :if => :properties
      end
    end

    module ClassMethods
      class DefinitionProxy
        def initialize(klass)
          @klass = klass
        end

        def column(name, default, type, options)
          if columns[name.to_s]
            raise TypeError.new("Property '#{name}' is already defined.")
          else
            new_column = Property::Column.new(name, default, type, options)
            own_columns[name] = new_column
            @klass.define_property_methods(new_column) if new_column.should_create_accessors?
          end
        end

        # If someday we find the need to insert other native classes directly in the DB, we
        # could use this:
        # p.serialize MyClass, xxx, xxx
        # def serialize(klass, name, options={})
        #   if @klass.super_property_columns[name.to_s]
        #     raise TypeError.new("Property '#{name}' is already defined in a superclass.")
        #   elsif !@klass.validate_property_class(type)
        #     raise TypeError.new("Custom type '#{type}' cannot be serialized.")
        #   else
        #     # Find a way to insert the type (maybe with 'serialize'...)
        #     # (@klass.own_property_columns ||= {})[name] = Property::Column.new(name, type, options)
        #   end
        # end

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
              column_names = args
              default = options.delete(:default)
              column_names.each { |name| column(name, default, '#{column_type}', options) }
            end
          EOV
        end

        private
          def own_columns
            @klass.own_property_columns ||= {}
          end

          def columns
            @klass.property_columns
          end

      end

      # Use this class method to declare properties that will be used in your models. Note
      # that you must provide string keys. Example:
      #  property.string 'phone', :default => ''
      #
      # You can also use a block:
      #  property do |p|
      #    p.string 'phone', 'name', :default => ''
      #  end
      def property
        proxy = self.property_definition_proxy ||= DefinitionProxy.new(self)
        if block_given?
          yield proxy
        end
        proxy
      end

      # Return the list of all properties defined for the current class, including the properties
      # defined in the parent class.
      def property_columns
        super_property_columns.merge(self.own_property_columns || {})
      end

      def property_column_names
        property_columns.keys
      end

      def super_property_columns
        if superclass.respond_to?(:property_columns)
          superclass.property_columns
        else
          {}
        end
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
          begin
            class_eval(method_definition, __FILE__, __LINE__)
          rescue SyntaxError => err
            if logger
              logger.warn "Exception occurred during method compilation."
              logger.warn "Maybe #{attr_name} is not a valid Ruby identifier?"
              logger.warn err.message
            end
          end
        end
    end # ClassMethods

    module InstanceMethods

      protected
        def properties_validation
          properties.validate
        end
    end # InsanceMethods
  end # Declaration
end # Property