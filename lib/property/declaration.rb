module Property

  # This module is used to manage property definitions (the schema) in a Class. The module
  # also manages property inheritence in sub-classes by linking the schema in the sub-class with
  # the schema in the superclass.
  module Declaration
    def self.included(base)
      base.class_eval do
        include Base
        validate :properties_validation, :if => :properties
      end
    end

    # This is just a helper module that includes the necessary code for property definition, but without
    # the validation/save hooks.
    module Base
      def self.included(base)
        base.class_eval do
          extend  ClassMethods
          include InstanceMethods

          class << self
            # Every class has it's own schema.
            attr_accessor :schema

            def schema
              @schema ||= make_schema
            end

            private
              # Build schema and manage inheritance.
              def make_schema
                Property::Schema.new(self.to_s, :class => self)
              end
          end
        end
      end
    end

    module ClassMethods

      # Include a new set of property definitions (Role) into the current class schema.
      # You can also provide a class to simulate multiple inheritance.
      def include_role(role)
        schema.include_role role
      end

      # Return true if the current object has all the roles of the given schema or role.
      def has_role?(role)
        schema.has_role? role
      end

      # Use this class method to declare properties and indices that will be used in your models.
      # Example:
      #  property.string 'phone', :default => '', :indexed => true
      #
      # You can also use a block:
      #  property do |p|
      #    p.string 'phone', 'name', :default => ''
      #    p.index(:string) do |r|
      #      {
      #        "name_#{r.lang}" => r.name,
      #      }
      #    end
      #  end
      def property(&block)
        schema.property(&block)
      end

      # Define property methods in a class. This is only triggered when properties are declared directly in the
      # class and not through Role inclusion.
      def define_property_methods(column)
        attr_name = column.name

        class_eval(%Q{
          def #{attr_name}                       # def title
            prop['#{attr_name}']                 #   prop['title']
          end                                    # end
                                                 #
          def #{attr_name}?                      # def title?
            prop['#{attr_name}']                 #   prop['title']
          end                                    # end
                                                 #
          def #{attr_name}=(new_value)           # def title=(new_value)
            prop['#{attr_name}'] = new_value     #   prop['title'] = new_value
          end                                    # end
        }, __FILE__, __LINE__)
      end
    end # ClassMethods

    module InstanceMethods
      # Instance's schema (can be different from the instance's class schema if roles have been
      # added to the instance.
      def schema
        @own_schema || self.class.schema
      end

      # Include a new set of property definitions (Role) into the current instance's schema.
      # You can also provide a class to simulate multiple inheritance.
      def include_role(role)
        own_schema.include_role role
      end

      # Return the list of active roles. The active roles are all the Roles included
      # in the current object for which properties have been defined (not blank).
      def used_roles
        own_schema.used_roles_in(self)
      end

      # Return true if the current object has all the roles of the given object, class or role.
      def has_role?(role)
        own_schema.has_role? role
      end

      protected
        def properties_validation
          properties.validate
        end

        def own_schema
          @own_schema ||= make_own_schema
        end

        # When roles are dynamically added to a model, we use method_missing to mimic property
        # accessors. Since this has a cost, it is better to use 'prop' based accessors in production
        # code (this is mostly helpful for testing/debugging).
        def method_missing(meth, *args, &block)
          method = meth.to_s
          if args.empty?
            if method[-1..-1] == '?'
              # predicate
              key = method[0..-2]
            else
              # reader
              key = method
            end

            if schema.has_column?(key)
              return prop[key]
            end
          elsif args.size == 1 && method[-1..-1] == '='
            # writer
            key = method[0..-2]
            if schema.has_column?(key)
              return prop[key] = args.first
            end
          end
          # Not a property method
          super
        end

      private
        # Create a schema for the instance and inherit from the class
        def make_own_schema
          Property::Schema.new(nil, :superschema => self.class.schema)
        end
    end # InsanceMethods
  end # Declaration
end # Property