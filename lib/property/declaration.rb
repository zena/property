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
            @schema ||= make_schema
          end

          private
            def make_schema
              schema = Property::Schema.new(self.to_s, self)
              if superclass.respond_to?(:schema)
                schema.behave_like superclass
              end
              schema
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
      end

      # Use this class method to declare properties and indexes that will be used in your models.
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
        schema.behavior.property(&block)
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
          @own_schema ||= make_own_schema
        end
      private
        def make_own_schema
          this = class << self; self; end
          schema = Property::Schema.new(nil, this)
          schema.behave_like self.class
          schema
        end
    end # InsanceMethods
  end # Declaration
end # Property