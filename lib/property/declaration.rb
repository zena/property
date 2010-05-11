module Property

  # Property::Declaration module is used to declare property definitions in a Class. The module
  # also manages property inheritence in sub-classes.
  module Declaration
    def self.included(base)
      base.class_eval do
        include Base
        validate :properties_validation, :if => :properties
      end
    end

    module Base
      def self.included(base)
        base.class_eval do
          extend  ClassMethods
          include InstanceMethods

          class << self
            attr_accessor :schema

            def schema
              @schema ||= make_schema
            end

            private
              def make_schema
                schema = Property::Schema.new(self.to_s, self)
                if superclass.respond_to?(:schema)
                  schema.has_role superclass
                end
                schema
              end
          end
        end
      end
    end

    module ClassMethods

      # Include a new set of property definitions (Role) into the current class schema.
      # You can also provide a class to simulate multiple inheritance.
      def has_role(role)
        schema.has_role role
      end

      # Return true if the current object has all the roles of the given object, class or role.
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
        schema.role.property(&block)
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
      def has_role(role)
        own_schema.has_role role
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
      private
        def make_own_schema
          this = class << self; self; end
          schema = Property::Schema.new(nil, this)
          schema.has_role self.class
          schema
        end
    end # InsanceMethods
  end # Declaration
end # Property