module Property
  # A schema contains all the property definitions for a given class. If Role is a module,
  # then schema is a Class.
  class Schema < Role
    include Property::SchemaModule

    # Initialize a new schema with a name and the klass linked to the schema.
    def initialize(name, opts = {})
      super
      initialize_schema_module(opts)
    end

  end
end # Property