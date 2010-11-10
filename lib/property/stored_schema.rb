require 'property/role_module'
require 'property/stored_column'

module Property
  # This module lets you use a custom class to store a schema inside
  # the database. The custom class must also include StoredRole.
  module StoredSchema
    include SchemaModule

    def self.included(base)
      base.class_eval do
        # Initialize a new schema with the given name
        def initialize(opts = {})
          klass = opts.delete(:class)
          superschema = opts.delete(:superschema)
          super
          initialize_schema_module(:class => klass, :superschema => superschema)
        end
      end
    end
  end
end
